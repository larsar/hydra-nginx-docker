#!/usr/bin/env bash

psmgr=/tmp/nginx-wait
rm -f $psmgr
mkfifo $psmgr

ADMIN_SOCKET=/var/run/admin_socket
PUBLIC_SOCKET=/var/run/public_socket
export DSN=$DATABASE_URL

# Heroku dynos have at least 4 cores.
worker_processes=${WORKER_PROCESSES:-4}

if [[ -z $PORT ]]; then
   echo "PORT must be set"
   exit -1
fi

if [[ -z $ADMIN_API_USERNAME ]]; then
   echo "ADMIN_API_USERNAME must be set"
   exit -1
fi

if [[ -z $ADMIN_API_PASSWORD_HASH ]]; then
   echo "ADMIN_API_PASSWORD_HASH must be set"
   exit -1
fi

sed -e "s/\${worker_processes}/$worker_processes/" -e "s/\${port}/$PORT/" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
echo $ADMIN_API_PASSWORD
echo "${ADMIN_API_USERNAME}:${ADMIN_API_PASSWORD_HASH}" > /etc/nginx/.htpasswd

n=1
while getopts :f option ${@:1:2}
do
  case "${option}"
  in
    f) FORCE=$OPTIND; n=$((n+1));;
  esac
done

# Initialize log directory.
mkdir -p logs/nginx
touch logs/nginx/access.log logs/nginx/error.log
echo 'at=logs-initialized'

# Start log redirection.
(
  # Redirect nginx logs to stdout.
  tail -qF -n 0 logs/nginx/*.log
  echo 'logs' >$psmgr
) &

# Start App Server
(
  # Take the command passed to this bin and start it.
  # E.g. bin/start-nginx bundle exec unicorn -c config/unicorn.rb
  COMMAND=${@:$n}
  echo "at=start-app cmd=$COMMAND"
  $COMMAND
  echo "ETTER OPPSTART"
  echo 'app' >$psmgr
) &

if [[ -z "$FORCE" ]]
then
  FILE="/tmp/app-initialized"

  # We block on app-initialized so that when nginx binds to $PORT
  # are app is ready for traffic.
  while [[ ! -e "$ADMIN_SOCKET" ]]
  do
    echo 'at=app-initialization'
    sleep 1
  done
  chmod 666 $ADMIN_SOCKET
  chmod 666 $PUBLIC_SOCKET
  echo 'at=app-initialized'
fi

ls -al $ADMIN_SOCKET

# Start nginx
(
  # We expect nginx to run in foreground.
  echo 'at=nginx-start'
  /usr/sbin/nginx -p . -c /etc/nginx/nginx.conf
  echo 'nginx' >$psmgr
) &

# This read will block the process waiting on a msg to be put into the fifo.
# If any of the processes defined above should exit,
# a msg will be put into the fifo causing the read operation
# to un-block. The process putting the msg into the fifo
# will use it's process name as a msg so that we can print the offending
# process to stdout.
read exit_process <$psmgr
echo "at=exit process=$exit_process"
exit 1

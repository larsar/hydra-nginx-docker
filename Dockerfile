FROM oryd/hydra

FROM nginx:1.17

COPY --from=0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=0 /usr/bin/hydra /usr/bin/
COPY ./start.sh /usr/bin/
COPY ./config/nginx.conf /etc/nginx/nginx.conf



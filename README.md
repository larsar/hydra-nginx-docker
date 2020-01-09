# Hydra with Nginx in Docker

Example code for deploying ORY Hydra to Heroku using Nginx as reverse proxy to protect the admin API. This example is based on [Heroku's nginx buildpack](https://github.com/heroku/heroku-buildpack-nginx).
Docker compose is only used for local testing.

# Run on localhost
Generate secrets: $ ./setup.sh
(Copy the password hash into the .env file. You only need to to this once.)

# Run on Heroku
Generate an admin password. This must be set as an evironment variable.
$ docker run -it --rm frapsoft/openssl passwd -apr1

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/larsar/hydra-nginx-docker)



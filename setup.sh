#!/usr/bin/env bash

if [[ -e .env ]]; then
    echo "Error: .env file already exists"
    exit -1
fi

echo "Generating random secret for Hydra..."
secrets_string=`docker run --rm ghcr.io/komed-health/pwgen 40 1`

echo "SECRETS_SYSTEM=$secrets_string" > .env
echo "Added secret to .env file"

echo "You must create a password for the admin api."
docker run -it --rm frapsoft/openssl passwd -apr1 
echo "ADMIN_API_PASSWORD_HASH=" >> .env

echo "Copy the password hash and paste it into the .env for the ADMIN_API_PASSWORD_HASH variable"

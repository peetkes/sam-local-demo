#!/bin/bash

export $(grep -v '^#' .env | xargs)
envsubst < sam.template > sam.env
envsubst < broker.template > broker.env

if docker image inspect "$SAM_IMAGE" > /dev/null 2>&1; then
  echo "Image $SAM_IMAGE exists locally."
else
  echo "Image $SAM_IMAGE does NOT exists locally. Loading..."
  docker load -i $SAM_IMAGE_TAR_FILE
fi

docker compose -f docker-compose.yml -p $PROJECT_NAME up -d
#!/bin/bash

export $(grep -v '^#' .env | xargs)
envsubst < sam.template > sam.env
envsubst < broker.template > broker.env
docker compose -f docker-compose.yml -p $PROJECT_NAME up -d
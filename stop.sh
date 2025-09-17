#!/bin/bash

export $(grep -v '^#' .env | xargs)
docker compose -f docker-compose.yml -p $PROJECT_NAME stop
#!/bin/bash

# Declare default platform for docker build for M1/M2 Mac
export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8

# check if there is .env file
if [ ! -f .env ]; then
    wget https://raw.githubusercontent.com/SiliconHealth/metabase-superset/main/Superset-Clickhouse/.env.example  -O ./.env.example
    echo "No .env file found, creating one from .env.example"
    cp .env.example .env
fi

#  Download Superset initial docker definition and source code
git clone https://github.com/apache/superset.git

# Get into superset folder
cd superset

# Create a a local requirement file
touch ./docker/requirements-local.txt

# Add clickhouse driver to the local requirement file
echo "clickhouse-connect>=0.6.8" >> ./docker/requirements-local.txt

# Get predefined compose file with clickhouse definition
wget https://raw.githubusercontent.com/SiliconHealth/metabase-superset/main/Superset-Clickhouse/superset-clickhouse-docker-compose.yml  -O ./superset-clickhouse-docker-compose.yml

# Build the docker image
docker compose build --force-rm

# Create predefined network for superset-clickhouse, if not existed yet
docker network inspect superset-clickhouse >/dev/null 2>&1 || ( echo "Network superset-clickhouse already existed")

# Run the docker image
docker compose -f superset-clickhouse-docker-compose.yml up -d

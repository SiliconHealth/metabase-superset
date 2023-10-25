#!/bin/bash

#  Download Superset initial docker definition and source code
git clone https://github.com/apache/superset.git

# Get into superset folder
cd superset

# Create a a local requirement file
touch ./docker/requirements-local.txt

# Add clickhouse driver to the local requirement file
echo "clickhouse-connect>=0.6.8" >> ./docker/requirements-local.txt

# Get predefined compose file with clickhouse definition
wget https://raw.githubusercontent.com/SiliconHealth/metabase-superset/main/Superset-Clickhouse/superset-clickhouse-docker-compose.yml 

# Build the docker image
docker compose build --force-rm -f superset-clickhouse-docker-compose.yml

# Create predefined network for superset-clickhouse, if not existed
docker network create superset-clickhouse

# Run the docker image
docker compose up -d -f superset-clickhouse-docker-compose.yml

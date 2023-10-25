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
docker compose build --force-rm

# Create predefined network for superset-clickhouse, if not existed yet
try 
(
  docker network inspect superset-clickhouse >/dev/null 2>&1 
)
catch || ( echo "Network superset-clickhouse already existed")

# Run the docker image
docker compose -f superset-clickhouse-docker-compose.yml up -d

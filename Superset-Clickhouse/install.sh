#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    export DOCKER_DEFAULT_PLATFORM=linux/arm64
    # Declare default platform for docker build for M1/M2 Mac
    CPU_BRAND=$(sysctl -n machdep.cpu.brand_string)
    if [[ $CPU_BRAND == *"M1"* || $CPU_BRAND == *"M2"* ]]; then
      export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8
      SUPERSET_PLATFORM=linux/x86_64
    fi
    SUPERSET_PLATFORM=$DOCKER_DEFAULT_PLATFORM

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    SUPERSET_PLATFORM=$DOCKER_DEFAULT_PLATFORM

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # Do something under 64 bits Windows NT platform
    export DOCKER_DEFAULT_PLATFORM=windows-amd64
    SUPERSET_PLATFORM=$DOCKER_DEFAULT_PLATFORM
fi

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


# Replace platform with specify platform

## Name of the Docker Compose file
compose_file="./superset-clickhouse-docker-compose.yml"

## Define the service name to search for
service_name="superset"

if [[ $CPU_BRAND == *"M1"* || $CPU_BRAND == *"M2"* ]]; then
  # Check if the service definition exists in the YAML file
  if yq eval ".services.$service_name" "$compose_file" > /dev/null 2>&1; then
      # Add the "platform" property to the service definition
      yq eval ".services.$service_name.platform = $(SUPERSET_PLATFORM)" -i "$compose_file"
      echo "Added 'platform' property to the '$service_name' service."
  else
      echo "Service '$service_name' not found in the Docker Compose file."
  fi
fi


# Build the docker image
docker compose build --force-rm

# Create predefined network for superset-clickhouse, if not existed yet
docker network inspect superset-clickhouse >/dev/null 2>&1 || ( echo "Network superset-clickhouse already existed")

# Run the docker image
docker compose -f superset-clickhouse-docker-compose.yml up -d

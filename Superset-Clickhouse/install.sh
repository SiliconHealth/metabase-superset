#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    brew install yq
    export DOCKER_DEFAULT_PLATFORM=linux/arm64/v8
    DB_PLATFORM=$DOCKER_DEFAULT_PLATFORM
    # Declare default platform for docker build for M1/M2 Mac
    CPU_BRAND=$(sysctl -n machdep.cpu.brand_string)
    if [[ $CPU_BRAND == *"M1"* || $CPU_BRAND == *"M2"* ]]; then
      echo "M1/M2 Mac detected, using linux/x86_64 as default platform"
      export DOCKER_DEFAULT_PLATFORM=linux/x86_64
      DB_PLATFORM=linux/arm64
    fi

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    DB_PLATFORM=$DOCKER_DEFAULT_PLATFORM
    yes | sudo apt install yq

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # Do something under 64 bits Windows NT platform
    export DOCKER_DEFAULT_PLATFORM=windows-amd64
    DB_PLATFORM=$DOCKER_DEFAULT_PLATFORM
fi

# check if there is .env file
if [ ! -f .env ]; then
    wget --no-cache --no-cookies https://raw.githubusercontent.com/SiliconHealth/metabase-superset/clickhouse-compose/Superset-Clickhouse/.env.example  -O ./.env.example
    echo "No .env file found, creating one from .env.example"
    cp .env.example ./.env
elif [ -f .env ]; then
    echo "Found .env file, using it"
    cp .env ./.env
fi

compose_file="./docker-compose.yml"

## Define the database service name to search for
clickhouse_service_name="clickhouse"


if [[ $CPU_BRAND == *"M1"* || $CPU_BRAND == *"M2"* ]]; then

  # clickhouse
  # Check if the service definition exists in the YAML file
  if yq eval ".services.$clickhouse_service_name" "$compose_file" > /dev/null 2>&1; then
      # Add the "platform" property to the service definition
      yq eval ".services.$clickhouse_service_name.platform = \"$DB_PLATFORM\"" -i "$compose_file"
      echo "Added 'platform' property to the '$clickhouse_service_name' service."
  else
      echo "Service '$clickhouse_service_name' not found in the Docker Compose file."
  fi

fi


# Build the docker image
docker compose -f docker-compose.yml build --force-rm

# Create predefined network for superset-clickhouse, if not existed yet
docker network inspect superset-clickhouse >/dev/null 2>&1 || ( echo "Network superset-clickhouse already existed")

# Create predefined volumes for composeed containers
# 1. `superset` for superset app
# 2. `clickhouse` for clickhouse data
# 3. `clickhouse_server` for clickhouse-server 
docker volume inspect superset >/dev/null 2>&1 || docker volume create superset
docker volume inspect clickhouse >/dev/null 2>&1 || docker volume create clickhouse
docker volume inspect clickhouse_server >/dev/null 2>&1 || docker volume create clickhouse_server

# Run the docker image
# docker compose -f superset-clickhouse-docker-compose.yml up -d
docker-compose -f docker-compose.yml up -d

echo "Waiting for Superset to start..."

read -p 'Do you want to create admin user? (y/n): ' adminvar

if [ $adminvar != "y" ]; then
    echo "No admin user created"
    echo "Superset is ready to use if you have created admin user before"
    echo "If not, please run 'docker exec -it superset_app superset fab create-admin' to create admin user"
    exit 1
fi

read -p 'Admin username: ' uservar
read -sp 'Admin password: ' passvar
read -sp 'Confirm Password: ' passvarConfirm

if [ $passvar != $passvarConfirm ]; then
    echo "Passwords do not match"
    exit 1
fi

# # Run the initialization process
docker exec -it superset_app superset fab create-admin \
              --username $uservar \
              --firstname Superset \
              --lastname Admin \
              --email admin@superset.com \
              --password $passvar

docker exec -it superset_app superset db upgrade
docker exec -it superset_app superset init

echo "Superset is ready to use"
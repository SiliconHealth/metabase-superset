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

#  Download Superset initial docker definition and source code
git clone https://github.com/apache/superset.git

# check if there is .env file
if [ ! -f .env ]; then
    wget --no-check-certificate --no-cache --no-cookies https://raw.githubusercontent.com/SiliconHealth/metabase-superset/clickhouse-compose/Superset-Clickhouse/.env.example  -O ./.env.example
    echo "No .env file found, creating one from .env.example"
    cp .env.example ./superset/.env
elif [ -f .env ]; then
    echo "Found .env file, using it"
    cp .env ./superset/.env
fi

# Get into superset folder
cd superset

# Create a a local requirement file
touch ./docker/requirements-local.txt

# Add clickhouse driver to the local requirement file
echo "clickhouse-connect>=0.6.8" >> ./docker/requirements-local.txt

# Get predefined compose file with clickhouse definition
wget --no-check-certificate --no-cache --no-cookies https://raw.githubusercontent.com/SiliconHealth/metabase-superset/clickhouse-compose/Superset-Clickhouse/superset-clickhouse-docker-compose.yml  -O ./superset-clickhouse-docker-compose.yml


# Replace platform with specify platform

## Name of the Docker Compose file
compose_file="./superset-clickhouse-docker-compose.yml"

## Define the database service name to search for
clickhouse_service_name="clickhouse"
db_service_name="db"
redis_service_name="redis"

## Define node service name
node_service="superset-node"

if [[ $CPU_BRAND == *"M1"* || $CPU_BRAND == *"M2"* ]]; then

  # Node 16
  # Check if the service definition exists in the YAML file
  if yq eval ".services.$node_service" "$compose_file" > /dev/null 2>&1; then
      # Add the "platform" property to the service definition
      yq eval ".services.$node_service.platform = \"linux/arm64/v8\"" -i "$compose_file"
      echo "Added 'platform' property to the '$node_service' service."
  else
      echo "Service '$node_service' not found in the Docker Compose file."
  fi

  # clickhouse
  # Check if the service definition exists in the YAML file
  if yq eval ".services.$clickhouse_service_name" "$compose_file" > /dev/null 2>&1; then
      # Add the "platform" property to the service definition
      yq eval ".services.$clickhouse_service_name.platform = \"$DB_PLATFORM\"" -i "$compose_file"
      echo "Added 'platform' property to the '$clickhouse_service_name' service."
  else
      echo "Service '$clickhouse_service_name' not found in the Docker Compose file."
  fi

  # redis
  # Check if the service definition exists in the YAML file
  if yq eval ".services.$redis_service_name" "$compose_file" > /dev/null 2>&1; then
      # Add the "platform" property to the service definition
      yq eval ".services.$redis_service_name.platform = \"$DB_PLATFORM\"" -i "$compose_file"
      echo "Added 'platform' property to the '$redis_service_name' service."
  else
      echo "Service '$redis_service_name' not found in the Docker Compose file."
  fi

  # db
  # Check if the service definition exists in the YAML file
  if yq eval ".services.$db_service_name" "$compose_file" > /dev/null 2>&1; then
      # Add the "platform" property to the service definition
      yq eval ".services.$db_service_name.platform = \"$DB_PLATFORM\"" -i "$compose_file"
      echo "Added 'platform' property to the '$db_service_name' service."
  else
      echo "Service '$db_service_name' not found in the Docker Compose file."
  fi

  # nginx
  # Check if the service definition exists in the YAML file
  if yq eval ".services.nginx" "$compose_file" > /dev/null 2>&1; then
      # Add the "platform" property to the service definition
      yq eval ".services.nginx.platform = \"linux/arm64/v8\"" -i "$compose_file"
      echo "Added 'platform' property to the 'nginx' service."
  else
      echo "Service 'nginx' not found in the Docker Compose file."
  fi

fi


# Build the docker image
docker compose build --force-rm

# Create predefined network for superset-clickhouse, if not existed yet
docker network inspect superset-clickhouse >/dev/null 2>&1 || ( echo "Network superset-clickhouse already existed")

# Run the docker image
docker compose -f superset-clickhouse-docker-compose.yml up -d

# # Run the initialization process
# docker exec -it superset_app superset fab create-admin \
#               --username admin \
#               --firstname Superset \
#               --lastname Admin \
#               --email admin@superset.com \
#               --password admin

docker exec -it superset_app superset db upgrade
docker exec -it superset_app superset init
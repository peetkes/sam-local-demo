# Solace Agent Mesh Demo


This repo is for use on linux like environments.

First step is to get the Enterprise image of the Solace Agent Mesh.
Find the instructions here: https://solacelabs.github.io/solace-agent-mesh/docs/documentation/Enterprise/installation

If you then do `docker load` it will put an image in your docker image registry with the format like this:
```
docker load -i solace-agent-mesh-enterprise-1.0.37.tar
Loaded image: 868978040651.dkr.ecr.us-east-1.amazonaws.com/solace-agent-mesh-enterprise:1.0.37-c8890c7f31
```
To rename that to something without the numbers you can execute this command:
```shell
docker load -i solace-agent-mesh-enterprise-1.0.37.tar | awk '{print $3}' | xargs -I {} docker tag {} solace/solace-agent-mesh-enterprise:1.0.37
```
This will give you a docker image with the name: `solace/solace-agent-mesh-enterprise:1.0.37` in line with the default image names for solace-pubsub.
The script 'prepare-image.sh' will do just that for you
If you have a newer version of the agent mesh you need to adjust the version.

Now you can create a copy of the `sample.env` file with all the environment variables used for Solace Agent Mesh and Solace Broker, adjust the keys to your need. Name the copuy '.env', this will be picked up automatically by the `start.sh` script.
```shell
PROJECT_NAME=sam-demo

SAM_IMAGE=solace/solace-agent-mesh-enterprise:1.0.37
SAM_NAME=sam-ent-prd
SAM_LLM_SERVICE_API_KEY=[your LiteLLM API key here]
SAM_LLM_SERVICE_ENDPOINT="https://lite-llm.mymaas.net/"
SAM_LLM_SERVICE_PLANNING_MODEL_NAME="openai/vertex-claude-4-sonnet"
SAM_LLM_SERVICE_GENERAL_MODEL_NAME="openai/vertex-claude-4-sonnet"
SAM_NAMESPACE="sam-demo"
SAM_DEV_MODE="false"
SAM_BROKER_PROTOCOL=ws
SAM_BROKER_PORT=8008
SAM_BROKER_VPN="default"
SAM_BROKER_USERNAME="default"
SAM_BROKER_PASSWORD="default"

BROKER_IMAGE=solace/solace-pubsub-standard:lts
BROKER_NAME=solace_broker
BROKER_ADMIN_NAME=admin
BROKER_ADMIN_PASSWORD=admin
BROKER_MAX_CONNECTION_COUNT=100
```
These environment variables will be used to prepare the environment variables for the Solace Agent Mesh and the Solace Broker when they are spinned up via the docker-compose file

There are 2 template environment files that are used with envsubst to create the separate env files for both containers.
- broker.template, used for the broker environment variables
- sam.template, used for the agent mesh envrionment variables

These files will be used by envsubst to create sam.env and broker.env used in teh docker-composefile 

Then in the docker-compose.yml file you can refer to both environment files and some environment variable from the original .env file

```shell
services:
  sam:
    image: ${SAM_IMAGE}
    container_name: ${SAM_NAME}
    hostname: ${SAM_NAME}
    env_file:
      - ./sam.env
    ports:
      - 8000:8000
    networks:
      - sam_net
    depends_on:
      solace_broker:
        condition: service_healthy

  solace_broker:
    image: ${BROKER_IMAGE}
    container_name: ${BROKER_NAME}
    hostname: ${BROKER_NAME}
    ports:
      # Standard ports
      - "8080:8080"   # SEMP HTTP
      - "8008:8008"   # WebSockets
      - "55554:55555" # SMF
      - "1883:1883"   # MQTT
      - "9000:8000"   # REST
      # TLS ports
      - "1443:1443"   # SEMP HTTPS
      - "55443:55443" # SMF TLS
      - "8883:8883"   # MQTT TLS
      - "9443:9443"   # REST TLS
      - '5550:5550'     # HealthCheck
    env_file:
      - ./broker.env
    networks:
      - sam_net
    volumes:
      - storage-group-1:/var/lib/solace
    shm_size: 1g
    ulimits:
      core: -1
      nofile:
        soft: 2448
        hard: 1048576
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5550/health-check/guaranteed-active"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 10s

networks:
  sam_net: {}

volumes:
  storage-group-1:
```

With the `start.sh` shell script you can start both containers. The Solace Agent Mesh will only start when the Solace Broker is fully up and running and return a healty status.
When both containers are up you can go to http://localhost:8000 to start the webUI and ask questions

With the `stop.sh` shell script you can stop both containers. The Solace broker state will be preserved in the attached volume so next time startup will be much faster.
With the 'down.sh' shell script you can completely remove all networks volumes and containers.

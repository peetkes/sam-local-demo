#!/bin/bash

docker load -i solace-agent-mesh-enterprise-1.0.37.tar | awk '{print $3}' | xargs -I {} docker tag {} my-solace/solace-agent-mesh-enterprise:1.0.37
#!/bin/bash

echo "Setting up local instance..."
influx setup -f -b docker -o influxdata -u admin -p something

echo "Initializing our stack..."
DOCKER_STACK_ID=$(influx stacks init -n docker --json | jq -r '.ID')

# Setting the base path
BASE_PATH="$(pwd)"

echo "Applying our stack..."
cat $BASE_PATH/docker/*.yml | \
influx apply --force true --stack-id $DOCKER_STACK_ID -q

# Check the last response to see if everything is ok
if [ $? -eq 0 ]; then
    echo "Everything was set up successfully!"
else
    echo "There was a problem applying the stack."
    exit 1
fi
#!/bin/bash

# assume default if nothing is passed in
CONFIG_PROFILE=${1:-"default"}

influx config set -n $CONFIG_PROFILE -a > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Successfully set config profile to $CONFIG_PROFILE..."
else
    echo "$CONFIG_PROFILE config profile not found..."
    if [ $CONFIG_PROFILE == "default" ]; then
        echo "Checking if there are any config profiles..."
        IS_SETUP=$(influx config ls --json | jq 'length')
        if [ $IS_SETUP -eq 0 ]; then
            echo "Couldn't find any config profiles, so let's"
            echo "try to set up the instance..."
            influx setup -f -b docker -o influxdata -u admin -p something
            if [ $? -eq 0 ]; then
                echo "Successfully set config profile to $CONFIG_PROFILE..."
            fi
        fi
    else
        echo "Config profile $CONFIG_PROFILE not found and there's no way to set it up. Exiting."
        exit 1
    fi
fi

echo "Checking for existing stacks..."
DOCKER_STACK_ID=$(influx stacks --stack-name docker --json | jq -r '.[0].ID')
if [ "$DOCKER_STACK_ID" == "null" ]; then
    echo "No stack found. Initializing our stack..."
    DOCKER_STACK_ID=$(influx stacks init -n docker --json | jq -r '.ID')
fi

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


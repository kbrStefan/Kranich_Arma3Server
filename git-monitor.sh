#!/bin/bash

# Notes for user arma allowed to restart the arma-server service without password:
# Add the following line to /etc/sudoers using visudo:
# arma ALL=NOPASSWD: /bin/systemctl restart arma-server.service

KRANICH_FOLDER=$(dirname "$0")
cd "${KRANICH_FOLDER}"


# Fetch latest changes
if ! git fetch; then
    echo "git fetch failed, aborting."
    exit 1
fi

# Check if there are new commits
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "New changes detected, pulling and restarting server..."
    if git pull; then
        if systemctl is-active --quiet arma-server.service; then
            sudo systemctl restart arma-server.service
        else
            echo "arma-server.service is not running, skipping restart."
        fi
        echo "git pull failed, aborting restart."
        exit 1
    fi
fi

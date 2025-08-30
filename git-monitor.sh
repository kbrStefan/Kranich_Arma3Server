#!/bin/bash

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
    git pull
    sudo systemctl restart arma-server.service
fi

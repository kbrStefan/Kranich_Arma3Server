#!/bin/bash

echo "entering kranich folder"
KRANICH_FOLDER=$(dirname "$0")
cd "${KRANICH_FOLDER}"


# Fetch latest changes
git fetch

# Check if there are new commits
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" != "$REMOTE" ]; then
    git pull
    systemctl restart arma3server.service
fi
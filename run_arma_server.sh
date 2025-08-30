#!/bin/bash

export MY_UID=$(id -u)

echo "entering kranich folder"
KRANICH_FOLDER=$(dirname "$0")
cd "${KRANICH_FOLDER}"


case "$1" in
  start)
    echo "Pulling latest changes from repository..."
    git pull
    echo "Starting container..."
    docker compose up --build -d
    ;;
  stop)
    echo "Stopping container..."
    docker compose stop
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

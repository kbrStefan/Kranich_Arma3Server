#!/bin/bash

export MY_UID=$(id -u)
export MY_GID=$(id -g)

echo "entering kranich folder"
cd "$(dirname "$0")"


case "$1" in
  start)
    echo "Pulling latest changes from repository..."
    git pull
    echo "Starting container..."
    docker compose up --build -d
    ;;
  stop)
    echo "Stopping container..."
    docker compose down
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

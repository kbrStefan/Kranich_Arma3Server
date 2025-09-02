#!/bin/bash

export MY_UID=$(id -u)


#echo "entering kranich folder"
KRANICH_FOLDER=$(dirname "$0")
cd "${KRANICH_FOLDER}"

TS_SERVER_FOLDER=../teamspeak
if [ ! -d "$TS_SERVER_FOLDER" ]; then
  echo "WARNING: Teamspeak server folder not found at $TS_SERVER_FOLDER"
fi

case "$1" in
  start)
    echo "Pulling latest changes from repository..."
    git pull
    if [ -d "$TS_SERVER_FOLDER" ]; then
      echo "Starting Teamspeak 3 server..."
      ${TS_SERVER_FOLDER}/ts3server_minimal_runscript.sh
    fi
    echo "Starting container..."
    docker compose up --build -d
    ;;
  stop)
    if [ -d "$TS_SERVER_FOLDER" ]; then
      echo "Stopping Teamspeak 3 server..."
      ${TS_SERVER_FOLDER}/ts3server_startscript.sh stop
    fi
    echo "Stopping container..."
    docker compose stop
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

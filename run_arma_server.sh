#!/bin/bash

export MY_UID=$(id -u)

echo "entering kranich folder"
KRANICH_FOLDER=$(dirname "$0")
cd "${KRANICH_FOLDER}"


case "$1" in
  start)
    echo "Pulling latest changes from repository..."
    git pull
    #echo "Mounting mods folder with ciopfs..."
    #ciopfs "${KRANICH_FOLDER}/steamapp/workshop/content/107410/" /home/arma/.steam/debian-installation/steamapps/workshop/content/107410/ 
    echo "Starting container..."
    docker compose up --build -d
    ;;
  stop)
    echo "Stopping container..."
    docker compose stop
    #echo "Unount mods folder..."
    #fusermount -u "${KRANICH_FOLDER}/steamapp/"
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

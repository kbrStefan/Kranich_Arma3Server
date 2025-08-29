#!/bin/bash

export MY_UID=$(id -u)

echo "entering kranich folder"
KRANICH_FOLDER=$(dirname "$0")
cd "${KRANICH_FOLDER}"


case "$1" in
  start)
    echo "Mounting mods folder with ciopfs..."
    mkdir -p ${KRANICH_FOLDER}/steamapp/workshop/content/107410/
    ciopfs ${KRANICH_FOLDER}/steamapp/workshop/content/107410/ /home/arma/.steam/debian-installation/steamapps/workshop/content/107410/ 
    sleep 2
    echo "Starting steam..."
    xvfb-run /usr/games/steam -silent &
    ;;
  stop)
    echo "Stopping steam..."
    killall steam
    echo "Unount mods folder..."
    fusermount -u /home/arma/.steam/debian-installation/steamapps/workshop/content/107410/
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

#!/bin/bash

EXIT_CODE=0

case "$1" in
  start)
    echo "Starting all services..."
    systemctl start arma-server.service
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      echo "Failed to start arma-server.service with exit code $EXIT_CODE"
    fi
    systemctl start teamspeak-server.service
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      echo "Failed to start teamspeak-server.service with exit code $EXIT_CODE"
    fi
    ;;
  stop)
    echo "Stopping all services..."
    systemctl stop arma-server.service
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      echo "Failed to stop arma-server.service with exit code $EXIT_CODE"
    fi
    systemctl stop teamspeak-server.service
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
      echo "Failed to stop teamspeak-server.service with exit code $EXIT_CODE"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
echo "Done! Exiting."
exit $EXIT_CODE
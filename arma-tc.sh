#!/bin/bash
CONTAINER_NAME="arma3_kranich"
RATE="75mbit"
INTERFACE=""
TC_ACTIVE=0

get_container_ip() {
    docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME" 2>/dev/null
}

get_bridge_interface() {
    local netid
    netid=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' "$CONTAINER_NAME" 2>/dev/null)
    if [ -n "$netid" ]; then
        echo "br-${netid:0:12}"
    else
        echo "docker0"
    fi
}

while true; do
    if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        if [ $TC_ACTIVE -eq 0 ]; then
            IP=$(get_container_ip)
            INTERFACE=$(get_bridge_interface)
            if [ -n "$IP" ]; then
                tc qdisc add dev $INTERFACE root handle 1: htb default 12 2>/dev/null
                tc class add dev $INTERFACE parent 1: classid 1:12 htb rate $RATE 2>/dev/null
                tc filter add dev $INTERFACE protocol ip prio 1 u32 match ip dst $IP flowid 1:12 2>/dev/null
                TC_ACTIVE=1
                echo "Traffic control enabled for $CONTAINER_NAME, IP: $IP on interface $INTERFACE"
            fi
        fi
    else
        if [ $TC_ACTIVE -eq 1 ]; then
            INTERFACE=$(get_bridge_interface)
            tc qdisc del dev $INTERFACE root 2>/dev/null
            TC_ACTIVE=0
            echo "Traffic control disabled for $CONTAINER_NAME, IP: $IP on interface $INTERFACE"
        fi
    fi
    sleep 10
done
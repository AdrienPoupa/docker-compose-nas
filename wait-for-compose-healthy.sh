#!/usr/bin/env bash
while true; do
    # Get count of containers still in "starting" state
    STARTING=$(docker compose ps --format json | jq -r 'select(.State == "running" and .Health == "starting") | .Name' | wc -l)
    
    if [ "$STARTING" -eq 0 ]; then
        echo "All containers are ready!"
        docker compose ps
        break
    fi
    
    clear
    echo "Waiting for containers to complete startup... ($STARTING remaining)"
    docker compose ps
    sleep 2
done

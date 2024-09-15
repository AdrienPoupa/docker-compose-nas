#!/bin/bash

port="$1"
QBT_PORT=8080

echo "Setting qBittorrent port settings ($port)..."

curl --silent --retry 10 --retry-delay 15 --max-time 10 \
  --data 'json={"listen_port": "'"$port"'"}' \
  --cookie /tmp/qb-cookies.txt \
  http://localhost:${QBT_PORT}/api/v2/app/setPreferences

echo "qBittorrent port updated successfully ($port)..."

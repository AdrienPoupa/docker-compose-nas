#!/bin/bash

port="$1"
QBT_USER=admin
QBT_PASS=adminadmin
QBT_PORT=8080

echo "Setting qBittorrent port settings ($port)..."
# Very basic retry logic so we don't fail if qBittorrent isn't running yet
 while ! curl --silent --retry 10 --retry-delay 15 --max-time 10 \
  --data "username=${QBT_USER}&password=${QBT_PASS}" \
  --cookie-jar /tmp/qb-cookies.txt \
  http://localhost:${QBT_PORT}/api/v2/auth/login
  do
    sleep 10
  done

curl --silent --retry 10 --retry-delay 15 --max-time 10 \
  --data 'json={"listen_port": "'"$port"'"}' \
  --cookie /tmp/qb-cookies.txt \
  http://localhost:${QBT_PORT}/api/v2/app/setPreferences

echo "qBittorrent port updated successfully ($port)..."

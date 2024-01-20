#!/bin/bash

# See https://stackoverflow.com/a/44864004 for the sed GNU/BSD compatible hack

function update_config {
  echo "Updating ${1^} configuration..."
  until [ -f ./$1/config.xml ]
  do
    sleep 5
  done
  sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/$1<\/UrlBase>/" ./$1/config.xml && rm ./$1/config.xml.bak
  sed -i.bak 's/^'"${1^^}"'_API_KEY=.*/'"${1^^}"'_API_KEY='"$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./$1/config.xml)"'/' .env && rm .env.bak
  echo "Update of ${1^} configuration complete."
  echo "Restarting ${1^}..."
  docker compose restart $1
}

for container in $(docker ps --format '{{.Names}}'); do
  if [[ $container =~ ^(radarr|sonarr|lidarr|prowlarr)$ ]]; then
    update_config $container
  elif [[ $container =~ ^(jellyfin)$ ]]; then
    echo "Updating ${container^} configuration..."
    until [ -f ./$container/network.xml ]; do
      sleep 5
    done
    sed -i.bak "s/<BaseUrl \/>/<BaseUrl>\/$container<\/BaseUrl>/" ./$container/network.xml && rm ./$container/network.xml.bak
    echo "Update of ${container^} configuration complete."
    echo "Restarting ${container^}..."
    docker compose restart $container
  fi
done

#!/bin/bash

# See https://stackoverflow.com/a/44864004 for the sed GNU/BSD compatible hack

function update_arr_config {
  echo "Updating ${container^} configuration..."
  until [ -f ./"$container"/config.xml ]
  do
    sleep 1
  done
  sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/$1<\/UrlBase>/" ./"$container"/config.xml && rm ./"$container"/config.xml.bak
  sed -i.bak 's/^'"${container^^}"'_API_KEY=.*/'"${1^^}"'_API_KEY='"$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./"$container"/config.xml)"'/' .env && rm .env.bak
  echo "Update of ${container^} configuration complete."
  echo "Restarting ${container^}..."
  docker compose restart "$container"
}

function update_jellyfin_config {
    echo "Updating ${container^} configuration..."
    until [ -f ./"$container"/network.xml ]; do
      sleep 1
    done
    sed -i.bak "s/<BaseUrl \/>/<BaseUrl>\/$container<\/BaseUrl>/" ./"$container"/network.xml && rm ./"$container"/network.xml.bak
    echo "Update of ${container^} configuration complete."
    echo "Restarting ${container^}..."
    docker compose restart "$container"
}

function update_bazarr_config {
    echo "Updating ${container^} configuration..."
    until [ -f ./"$container"/config/config/config.yaml ]; do
      sleep 1
    done
    sed -i.bak "s/base_url: ''/base_url: '\/$container'/" ./"$container"/config/config/config.yaml && rm ./"$container"/config/config/config.yaml.bak
    sed -i.bak "s/use_radarr: false/use_radarr: true/" ./"$container"/config/config/config.yaml && rm ./"$container"/config/config/config.yaml.bak
    sed -i.bak "s/use_sonarr: false/use_sonarr: true/" ./"$container"/config/config/config.yaml && rm ./"$container"/config/config/config.yaml.bak
    SONARR_API_KEY=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./sonarr/config.xml)
    sed -i.bak "/sonarr:/,/^radarr:/ { s/apikey: .*/apikey: $SONARR_API_KEY/; s/base_url: .*/base_url: \/sonarr/; s/ip: .*/ip: sonarr/ }" "$container"/config/config/config.yaml && rm ./"$container"/config/config/config.yaml.bak
    RADARR_API_KEY=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./radarr/config.xml)
    sed -i.bak "/radarr:/,/^sonarr:/ { s/apikey: .*/apikey: $RADARR_API_KEY/; s/base_url: .*/base_url: \/radarr/; s/ip: .*/ip: radarr/ }" "$container"/config/config/config.yaml && rm ./"$container"/config/config/config.yaml.bak
    sed -i.bak 's/^'"${container^^}"'_API_KEY=.*/'"${container^^}"'_API_KEY='"$(sed -n 's/.*apikey: \(.*\)*/\1/p' ./"$container"/config/config/config.yaml | head -n 1)"'/' .env && rm .env.bak
    echo "Update of ${container^} configuration complete."
    echo "Restarting ${container^}..."
    docker compose restart "$container"
}

for container in $(docker ps --format '{{.Names}}'); do
  if [[ "$container" =~ ^(radarr|sonarr|lidarr|prowlarr)$ ]]; then
    update_arr_config "$container"
  elif [[ "$container" =~ ^(jellyfin)$ ]]; then
    update_jellyfin_config "$container"
  elif [[ "$container" =~ ^(bazarr)$ ]]; then
    update_bazarr_config "$container"
  fi
done

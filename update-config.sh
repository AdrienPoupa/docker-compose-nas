#!/bin/bash

# See https://stackoverflow.com/a/44864004 for the sed GNU/BSD compatible hack

echo "Updating Radarr configuration..."
until [ -f ./radarr/config.xml ]
do
  sleep 5
done
sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/radarr<\/UrlBase>/" ./radarr/config.xml && rm ./radarr/config.xml.bak

echo "Updating Sonarr configuration..."
until [ -f ./sonarr/config.xml ]
do
  sleep 5
done
sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/sonarr<\/UrlBase>/" ./sonarr/config.xml && rm ./sonarr/config.xml.bak

echo "Updating Prowlarr configuration..."
until [ -f ./prowlarr/config.xml ]
do
  sleep 5
done
sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/prowlarr<\/UrlBase>/" ./prowlarr/config.xml && rm ./prowlarr/config.xml.bak

echo "Updating Jellyfin configuration..."
until [ -f ./jellyfin/network.xml ]
do
  sleep 5
done
sed -i.bak "s/<BaseUrl \/>/<BaseUrl>\/jellyfin<\/BaseUrl>/" ./jellyfin/network.xml && rm ./jellyfin/network.xml.bak

echo "Restarting containers..."
docker compose restart radarr sonarr prowlarr jellyfin

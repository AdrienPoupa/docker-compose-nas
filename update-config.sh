#!/bin/bash

# See https://stackoverflow.com/a/44864004 for the sed GNU/BSD compatible hack

echo "Updating Radarr configuration..."
until [ -f ./radarr/config.xml ]
do
  sleep 5
done
sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/radarr<\/UrlBase>/" ./radarr/config.xml && rm ./radarr/config.xml.bak
sed -i.bak 's/^RADARR_API_KEY=.*/RADARR_API_KEY='"$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./radarr/config.xml)"'/' .env && rm .env.bak

echo "Updating Sonarr configuration..."
until [ -f ./sonarr/config.xml ]
do
  sleep 5
done
sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/sonarr<\/UrlBase>/" ./sonarr/config.xml && rm ./sonarr/config.xml.bak
sed -i.bak 's/^SONARR_API_KEY=.*/SONARR_API_KEY='"$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./sonarr/config.xml)"'/' .env && rm .env.bak

echo "Updating Lidarr configuration..."
until [ -f ./lidarr/config.xml ]
do
  sleep 5
done
sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/lidarr<\/UrlBase>/" ./lidarr/config.xml && rm ./lidarr/config.xml.bak
sed -i.bak 's/^LIDARR_API_KEY=.*/LIDARR_API_KEY='"$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./lidarr/config.xml)"'/' .env && rm .env.bak

echo "Updating Prowlarr configuration..."
until [ -f ./prowlarr/config.xml ]
do
  sleep 5
done
sed -i.bak "s/<UrlBase><\/UrlBase>/<UrlBase>\/prowlarr<\/UrlBase>/" ./prowlarr/config.xml && rm ./prowlarr/config.xml.bak
sed -i.bak 's/^PROWLARR_API_KEY=.*/PROWLARR_API_KEY='"$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' ./prowlarr/config.xml)"'/' .env && rm .env.bak

echo "Restarting containers..."
docker-compose restart radarr sonarr prowlarr

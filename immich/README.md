# Immich

Self-hosted photo and video management solution

## Installation

Enable Immich by setting `COMPOSE_PROFILES=immich`.

Set the `IMMICH_HOSTNAME`, since it does not support
[running in a subfolder](https://github.com/immich-app/immich/discussions/1679#discussioncomment-7276351).
Add the necessary DNS records in your domain.

## Environment Variables

| Variable                 | Description                                          | Default            |
|--------------------------|------------------------------------------------------|--------------------|
| `IMMICH_HOSTNAME`        | URL Immich will be accessible from                   |                    |
| `IMMICH_UPLOAD_LOCATION` | Path where the assets will be stored                 | `/mnt/data/photos` |
| `IMMICH_API_KEY`         | Immich API key to show information in the homepage   | `1000`             |
| `IMMICH_DB_PASSWORD`     | Postgres database password, change for more security | `postgres`         |

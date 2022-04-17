# Docker Compose NAS

After searching for the perfect NAS solution, I realized what I wanted could be achieved 
with some Docker containers on a vanilla Linux box. The result is an opinionated Docker Compose configuration capable of 
browsing indexers to retrieve media resources and downloading them through a Wireguard VPN with port forwarding.

## Applications

The following applications are available:

- [Sonarr](https://sonarr.tv/): PVR for newsgroup and bittorrent users
- [Radarr](https://radarr.video/): Movie collection manager for Usenet and BitTorrent users
- [Prowlarr](https://github.com/Prowlarr/Prowlarr): Indexer aggregator for Sonarr and Radarr
- [qBittorrent](https://www.qbittorrent.org/): Bittorrent client with a complete web UI
- [PIA Wireguard VPN](https://github.com/thrnz/docker-wireguard-pia): Encapsulate qBittorrent traffic in 
[PIA](https://www.privateinternetaccess.com/) with [Wireguard](https://www.wireguard.com/) with port forwarding.
- [Heimdall](https://heimdall.site/): Application dashboard
- [Traefik](https://traefik.io/): Reverse proxy

## Installation

See [installation instructions](./INSTALL.md).

TLDR: `cp .env.example .env`, edit to your needs then `sudo docker compose up -d`, then for the first time `./update-config.sh`.

## Configuration

See [configuration](./CONFIGURATION.md).

## Containers

| **Application**   | **Image**                                                                          | **URL**      | **Notes**                                                         |
|-------------------|------------------------------------------------------------------------------------|--------------|-------------------------------------------------------------------|
| Sonarr            | [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)                  | /sonarr      |                                                                   |
| Radarr            | [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)                  | /radarr      |                                                                   |
| Prowlarr          | [linuxserver/prowlarr:develop](https://hub.docker.com/r/linuxserver/prowlarr)      | /prowlarr    | `develop` tag as it is not stable yet                             |
| PIA Wireguard VPN | [thrnz/docker-wireguard-pia](https://hub.docker.com/r/thrnz/docker-wireguard-pia)  |              |                                                                   |
| qBittorrent       | [linuxserver/qbittorrent:14.3.9](https://hub.docker.com/r/linuxserver/qbittorrent) | /qbittorrent | Uses VPN network<br>Frozen to v4.3.9 due to Libtorrent 2.x issues |
| Heimdall          | [linuxserver/heimdall](https://hub.docker.com/r/linuxserver/heimdall)              | /            |                                                                   |
| Traefik           | [traefik](https://hub.docker.com/_/traefik)                                        |              |                                                                   |


## Improvement

There is always room for improvement. I did not need those containers, so I did not include them, but maybe you could
benefit from:

- [Bazarr](https://www.bazarr.media/): companion application to Sonarr and Radarr that manages and downloads subtitles
- [Lidarr](https://lidarr.audio/): music collection manager for Usenet and BitTorrent users
- [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr): Proxy server to bypass Cloudflare protection, useful
for some indexers in Prowlarr
- [Jackett](https://github.com/Jackett/Jackett): API Support for your favorite torrent trackers, as a Prowlarr replacement
- [Plex](https://www.plex.tv/): Plex Media Server
- [Pi-hole](https://pi-hole.net/): DNS that blocks ads
- Use a domain name and Let's Encrypt certificate to get SSL
- Expose services with CloudFlare Tunnel
- you tell me!

# Docker Compose NAS

After searching for the perfect NAS solution, I realized what I wanted could be achieved 
with some Docker containers on a vanilla Linux box. The result is an opinionated Docker Compose configuration capable of 
browsing indexers to retrieve media resources and downloading them through a WireGuard VPN with port forwarding.
SSL certificates and remote access through Tailscale are supported.

Requirements: Any Docker-capable recent Linux box with Docker Engine and Docker Compose V2.
I am running it in Ubuntu Server 22.04; I also tested this setup on a [Synology DS220+ with DSM 7.1](#synology-quirks).

![Docker-Compose NAS Homepage](https://github.com/AdrienPoupa/docker-compose-nas/assets/15086425/3492a9f6-3779-49a5-b052-4193844f16f0)

## Table of Contents

<!-- TOC -->
* [Docker Compose NAS](#docker-compose-nas)
  * [Table of Contents](#table-of-contents)
  * [Applications](#applications)
  * [Quick Start](#quick-start)
  * [Environment Variables](#environment-variables)
  * [PIA WireGuard VPN](#pia-wireguard-vpn)
  * [Sonarr, Radarr & Lidarr](#sonarr-radarr--lidarr)
    * [File Structure](#file-structure)
    * [Download Client](#download-client)
  * [Prowlarr](#prowlarr)
  * [qBittorrent](#qbittorrent)
  * [Jellyfin](#jellyfin)
  * [Homepage](#homepage)
  * [Jellyseerr](#jellyseerr)
  * [Traefik and SSL Certificates](#traefik-and-ssl-certificates)
    * [Accessing from the outside with Tailscale](#accessing-from-the-outside-with-tailscale)
  * [Optional Services](#optional-services)
    * [FlareSolverr](#flaresolverr)
    * [SABnzbd](#sabnzbd)
    * [AdGuard Home](#adguard-home)
      * [Encryption](#encryption)
      * [DHCP](#dhcp)
      * [Expose DNS Server with Tailscale](#expose-dns-server-with-tailscale)
  * [Customization](#customization)
    * [Optional: Using the VPN for *arr apps](#optional-using-the-vpn-for-arr-apps)
  * [Synology Quirks](#synology-quirks)
    * [Free Ports 80 and 443](#free-ports-80-and-443)
    * [Install Synology WireGuard](#install-synology-wireguard)
    * [Free Port 1900](#free-port-1900)
    * [User Permissions](#user-permissions)
    * [Synology DHCP Server and Adguard Home Port Conflict](#synology-dhcp-server-and-adguard-home-port-conflict)
  * [Use Separate Paths for Torrents and Storage](#use-separate-paths-for-torrents-and-storage)
  * [NFS Share](#nfs-share)
  * [Static IP](#static-ip)
  * [Laptop Specific Configuration](#laptop-specific-configuration)
<!-- TOC -->

## Applications

| **Application**                                                      | **Description**                                                                                                                                      | **Image**                                                                                | **URL**      |
|----------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|--------------|
| [Sonarr](https://sonarr.tv)                                          | PVR for newsgroup and bittorrent users                                                                                                               | [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)                        | /sonarr      |
| [Radarr](https://radarr.video)                                       | Movie collection manager for Usenet and BitTorrent users                                                                                             | [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)                        | /radarr      |
| [Lidarr](https://lidarr.audio)                                       | Music collection manager for Usenet and BitTorrent users                                                                                             | [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)                        | /lidarr      |
| [Prowlarr](https://github.com/Prowlarr/Prowlarr)                     | Indexer aggregator for Sonarr and Radarr                                                                                                             | [linuxserver/prowlarr:latest](https://hub.docker.com/r/linuxserver/prowlarr)             | /prowlarr    |
| [PIA WireGuard VPN](https://github.com/thrnz/docker-wireguard-pia)   | Encapsulate qBittorrent traffic in [PIA](https://www.privateinternetaccess.com/) using [WireGuard](https://www.wireguard.com/) with port forwarding. | [thrnz/docker-wireguard-pia](https://hub.docker.com/r/thrnz/docker-wireguard-pia)        |              |
| [qBittorrent](https://www.qbittorrent.org)                           | Bittorrent client with a complete web UI<br/>Uses VPN network<br/>Using Libtorrent 1.x                                                               | [linuxserver/qbittorrent:libtorrentv1](https://hub.docker.com/r/linuxserver/qbittorrent) | /qbittorrent |
| [Jellyfin](https://jellyfin.org)                                     | Media server designed to organize, manage, and share digital media files to networked devices                                                        | [linuxserver/jellyfin](https://hub.docker.com/r/linuxserver/jellyfin)                    | /jellyfin    |
| [Jellyseer](https://jellyfin.org)                                    | Manages requests for your media library                                                                                                              | [fallenbagel/jellyseerr](https://hub.docker.com/r/fallenbagel/jellyseerr)                | /jellyseer   |
| [Homepage](https://gethomepage.dev)                                  | Application dashboard                                                                                                                                | [gethomepage/homepage](https://github.com/gethomepage/homepage/pkgs/container/homepage)  | /            |
| [Traefik](https://traefik.io)                                        | Reverse proxy                                                                                                                                        | [traefik](https://hub.docker.com/_/traefik)                                              |              |
| [Watchtower](https://containrrr.dev/watchtower/)                     | Automated Docker images update                                                                                                                       | [containrrr/watchtower](https://hub.docker.com/r/containrrr/watchtower)                  |              |
| [Autoheal](https://github.com/willfarrell/docker-autoheal/)          | Monitor and restart unhealthy docker containers                                                                                                      | [willfarrell/autoheal](https://hub.docker.com/r/willfarrell/autoheal)                    |              |
| [SABnzbd](https://sabnzbd.org/)                                      | Optional - Free and easy binary newsreader                                                                                                           | [linuxserver/sabnzbd](https://hub.docker.com/r/linuxserver/sabnzbd)                      | /sabnzbd     |
| [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr)         | Optional - Proxy server to bypass Cloudflare protection in Prowlarr                                                                                  | [flaresolverr/flaresolverr](https://hub.docker.com/r/flaresolverr/flaresolverr)          |              |
| [AdGuard Home](https://adguard.com/en/adguard-home/overview.html)    | Optional - Network-wide software for blocking ads & tracking                                                                                         | [adguard/adguardhome](https://hub.docker.com/r/adguard/adguardhome)                      |              |
| [DHCP Relay](https://github.com/modem7/DHCP-Relay)                   | Optional - Docker DHCP Relay                                                                                                                         | [modem7/dhcprelay](https://hub.docker.com/r/modem7/dhcprelay)                            |              |
| [Traefik Certs Dumper](https://github.com/ldez/traefik-certs-dumper) | Optional - Dump ACME data from Traefik to certificates                                                                                               | [ldez/traefik-certs-dumper](https://hub.docker.com/r/ldez/traefik-certs-dumper)          |              |

Optional containers are not run by default, they need to be enabled, 
see [Optional Services](#optional-services) for more information.

## Quick Start

`cp .env.example .env`, edit to your needs then `sudo docker compose up -d`.

For the first time, run `./update-config.sh` to update the applications base URLs and set the API keys in `.env`.

If you want to show Jellyfin information in the homepage, create it in Jellyfin settings and fill `JELLYFIN_API_KEY`.

## Environment Variables

| Variable                       | Description                                                                                                                                                                                            | Default                                          |
|--------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| `COMPOSE_FILE`                 | Docker compose files to load                                                                                                                                                                           | `docker-compose.yml`                             |
| `COMPOSE_PATH_SEPARATOR`       | Path separator between compose files to load                                                                                                                                                           | `:`                                              |
| `USER_ID`                      | ID of the user to use in Docker containers                                                                                                                                                             | `1000`                                           |
| `GROUP_ID`                     | ID of the user group to use in Docker containers                                                                                                                                                       | `1000`                                           |
| `TIMEZONE`                     | TimeZone used by the container.                                                                                                                                                                        | `America/New_York`                               |
| `DATA_ROOT`                    | Host location of the data files                                                                                                                                                                        | `/mnt/data`                                      |
| `DOWNLOAD_ROOT`                | Host download location for qBittorrent, should be a subfolder of `DATA_ROOT`                                                                                                                           | `/mnt/data/torrents`                             |
| `PIA_LOCATION`                 | Servers to use for PIA. [see list here](https://serverlist.piaservers.net/vpninfo/servers/v6)                                                                                                          | `ca` (Montreal, Canada)                          |
| `PIA_USER`                     | PIA username                                                                                                                                                                                           |                                                  |
| `PIA_PASS`                     | PIA password                                                                                                                                                                                           |                                                  |
| `PIA_LOCAL_NETWORK`            | PIA local network                                                                                                                                                                                      | `192.168.0.0/16`                                 |
| `HOSTNAME`                     | Hostname of the NAS, could be a local IP or a domain name                                                                                                                                              | `localhost`                                      |
| `ADGUARD_HOSTNAME`             | Optional - AdGuard Home hostname used, if enabled                                                                                                                                                      |                                                  |
| `ADGUARD_USERNAME`             | Optional - AdGuard Home username to show details in the homepage, if enabled                                                                                                                           |                                                  |
| `ADGUARD_PASSWORD`             | Optional - AdGuard Home password to show details in the homepage, if enabled                                                                                                                           |                                                  |
| `QBITTORRENT_USERNAME`         | qBittorrent username to access the web UI                                                                                                                                                              | `admin`                                          |
| `QBITTORRENT_PASSWORD`         | qBittorrent password to access the web UI                                                                                                                                                              | `adminadmin`                                     |
| `DNS_CHALLENGE`                | Enable/Disable DNS01 challenge, set to `false` to disable.                                                                                                                                             | `true`                                           |
| `DNS_CHALLENGE_PROVIDER`       | Provider for DNS01 challenge, [see list here](https://doc.traefik.io/traefik/https/acme/#providers).                                                                                                   | `cloudflare`                                     |
| `LETS_ENCRYPT_CA_SERVER`       | Let's Encrypt CA Server used to generate certificates, set to production by default.<br/>Set to `https://acme-staging-v02.api.letsencrypt.org/directory` to test your changes with the staging server. | `https://acme-v02.api.letsencrypt.org/directory` |
| `LETS_ENCRYPT_EMAIL`           | E-mail address used to send expiration notifications                                                                                                                                                   |                                                  |
| `CLOUDFLARE_EMAIL`             | CloudFlare Account email                                                                                                                                                                               |                                                  |
| `CLOUDFLARE_DNS_API_TOKEN`     | API token with `DNS:Edit` permission                                                                                                                                                                   |                                                  |
| `CLOUDFLARE_ZONE_API_TOKEN`    | API token with `Zone:Read` permission                                                                                                                                                                  |                                                  |
| `SONARR_API_KEY`               | Sonarr API key to show information in the homepage                                                                                                                                                     |                                                  |
| `RADARR_API_KEY`               | Radarr API key to show information in the homepage                                                                                                                                                     |                                                  |
| `LIDARR_API_KEY`               | Lidarr API key to show information in the homepage                                                                                                                                                     |                                                  |
| `PROWLARR_API_KEY`             | Prowlarr API key to show information in the homepage                                                                                                                                                   |                                                  |
| `JELLYFIN_API_KEY`             | Jellyfin API key to show information in the homepage                                                                                                                                                   |                                                  |
| `JELLYSEERR_API_KEY`           | Jellyseer API key to show information in the homepage                                                                                                                                                  |                                                  |
| `HOMEPAGE_VAR_TITLE`           | Title of the homepage                                                                                                                                                                                  | `Docker-Compose NAS`                             |
| `HOMEPAGE_VAR_SEARCH_PROVIDER` | Homepage search provider, [see list here](https://gethomepage.dev/en/widgets/search/)                                                                                                                  | `google`                                         |
| `HOMEPAGE_VAR_HEADER_STYLE`    | Homepage header style, [see list here](https://gethomepage.dev/en/configs/settings/#header-style)                                                                                                      | `boxed`                                          |
| `HOMEPAGE_VAR_WEATHER_CITY`    | Homepage weather city name                                                                                                                                                                             |                                                  |
| `HOMEPAGE_VAR_WEATHER_LAT`     | Homepage weather city latitude                                                                                                                                                                         |                                                  |
| `HOMEPAGE_VAR_WEATHER_LONG`    | Homepage weather city longitude                                                                                                                                                                        |                                                  |
| `HOMEPAGE_VAR_WEATHER_UNIT`    | Homepage weather unit, either `metric` or `imperial`                                                                                                                                                   | `metric`                                         |

## PIA WireGuard VPN

I chose PIA since it supports WireGuard and [port forwarding](https://github.com/thrnz/docker-wireguard-pia/issues/26#issuecomment-868165281),
but you could use other providers:

- OpenVPN: [linuxserver/openvpn-as](https://hub.docker.com/r/linuxserver/openvpn-as)
- WireGuard: [linuxserver/wireguard](https://hub.docker.com/r/linuxserver/wireguard)
- NordVPN + OpenVPN: [bubuntux/nordvpn](https://hub.docker.com/r/bubuntux/nordvpn/dockerfile)
- NordVPN + WireGuard (NordLynx): [bubuntux/nordlynx](https://hub.docker.com/r/bubuntux/nordlynx)

For PIA + WireGuard, fill `.env` and fill it with your PIA credentials.

The location of the server it will connect to is set by `LOC=ca`, defaulting to Montreal - Canada.

You need to fill the credentials in the `PIA_*` environment variable, 
otherwise the VPN container will exit and qBittorrent will not start.

## Sonarr, Radarr & Lidarr

### File Structure

Sonarr, Radarr, and Lidarr must be configured to support hardlinks, to allow instant moves and prevent using twice the storage
(Bittorrent downloads and final file). The trick is to use a single volume shared by the Bittorrent client and the *arrs.
Subfolders are used to separate the TV shows from the movies.

The configuration is well explained by [this guide](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/).

In summary, the final structure of the shared volume will be as follows:

```
data
├── torrents = shared folder qBittorrent downloads
│  ├── movies = movies downloads tagged by Radarr
│  └── tv = movies downloads tagged by Sonarr
└── media = shared folder for Sonarr and Radarr files
   ├── movies = Radarr
   └── tv = Sonarr
   └── music = Lidarr
```

Go to Settings > Management.
In Sonarr, set the Root folder to `/data/media/tv`.
In Radarr, set the Root folder to `/data/media/movies`.
In Lidarr, set the Root folder to `/data/media/music`.

### Download Client

Then qBittorrent can be configured at Settings > Download Clients. Because all the networking for qBittorrent takes
place in the VPN container, the hostname for qBittorrent is the hostname of the VPN container, ie `vpn`, and the port is `8080`:

## Prowlarr

The indexers are configured through Prowlarr. They synchronize automatically to Radarr and Sonarr.

Radarr and Sonarr may then be added via Settings > Apps. The Prowlarr server is `http://prowlarr:9696/prowlarr`, the Radarr server
is `http://radarr:7878/radarr` Sonarr `http://sonarr:8989/sonarr`, and Lidarr `http://lidarr:8686/lidarr`:

Their API keys can be found in Settings > Security > API Key.

## qBittorrent

Set the default save path to `/data/torrents` in Settings, and restrict the network interface to WireGuard (`wg0`).

The web UI login page can be disabled on for the local network in Settings > Web UI > Bypass authentication for clients

```
192.168.0.0/16
127.0.0.0/8
172.17.0.0/16
```

## Jellyfin

To enable [hardware transcoding](https://jellyfin.org/docs/general/administration/hardware-acceleration/),
depending on your system, you may need to update the following block:

```    
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128
  - /dev/dri/card0:/dev/dri/card0
```

Generally, running Docker on Linux you will want to use VA-API, but the exact mount paths may differ depending on your
hardware.

## Homepage

The homepage comes with sensible defaults; some settings can ben controlled via environment variables in `.env`.

If you to customize further, you can modify the files in `/homepage/*.yaml` according to the [documentation](https://gethomepage.dev). 
Due to how the Docker socket is configured for the Docker integration, files must be edited as root.

The files in `/homepage/tpl/*.yaml` only serve as a base to set up the homepage configuration on first run.

## Jellyseerr

Jellyseer gives you content recommendations, allows others to make requests to you, and allows logging in with Jellyfin credentials.

To setup, go to https://hostname/jellyseerr/setup, and set the URLs as follows:
- Jellyfin: http://jellyfin:8096/jellyfin
- Radarr:
  - Hostname: radarr
  - Port: 7878
  - URL Base: /radarr
- Sonarr
  - Hostname: sonarr
  - Port: 8989
  - URL Base: /sonarr

## Traefik and SSL Certificates

While you can use the private IP to access your NAS, how cool would it be for it to be accessible through a subdomain
with a valid SSL certificate?

Traefik makes this trivial by using Let's Encrypt and one of its
[supported ACME challenge providers](https://doc.traefik.io/traefik/https/acme).

Let's assume we are using `nas.domain.com` as custom subdomain.

The idea is to create an A record pointing to the private IP of the NAS, `192.168.0.10` for example:
```
nas.domain.com.	1	IN	A	192.168.0.10
```

The record will be publicly exposed but not resolve given this is a private IP.

Given the NAS is not accessible from the internet, we need to do a dnsChallenge.
Here we will be using CloudFlare, but the mechanism will be the same for all DNS providers
baring environment variable changes, see the Traefik documentation above and [Lego's documentation](https://go-acme.github.io/lego/dns).

Then, fill the CloudFlare `.env` entries.

If you want to test your configuration first, use the Let's Encrypt staging server by updating `LETS_ENCRYPT_CA_SERVER`'s
value in `.env`:
```
LETS_ENCRYPT_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
```

If it worked, you will see the staging certificate at https://nas.domain.com.
You may remove the `./letsencrypt/acme.json` file and restart the services to issue the real certificate.

You are free to use any DNS01 provider. Simply replace `DNS_CHALLENGE_PROVIDER` with your own provider, 
[see complete list here](https://doc.traefik.io/traefik/https/acme/#providers). 
You will also need to inject the environments variables specific to your provider.

Certificate generation can be disabled by setting `DNS_CHALLENGE` to `false`.

### Accessing from the outside with Tailscale

If we want to make it reachable from outside the network without opening ports or exposing it to the internet, I found
[Tailscale](https://tailscale.com) to be a great solution: create a network, run the client on both the NAS and the device
you are connecting from, and they will see each other.

In this case, the A record should point to the IP Tailscale assigned to the NAS, eg `100.xxx.xxx.xxx`:
```
nas.domain.com.	1	IN	A	100.xxx.xxx.xxx
```

See [here](https://tailscale.com/kb/installation) for installation instructions.

However, this means you will always need to be connected to Tailscale to access your NAS, even locally.
This can be remedied by overriding the DNS entry for the NAS domain like `192.168.0.10 nas.domain.com`
in your local DNS resolver such as Pi-Hole.

This way, when connected to the local network, the NAS is accessible directly from the private IP,
and from the outside you need to connect to Tailscale first, then the NAS domain will be accessible.

## Optional Services

As their name would suggest, optional services are not launched by default. They have their own `docker-compose.yml` file
in their subfolders. To enable a service, append it to the `COMPOSE_FILE` environment variable.

Say you want to enable FlareSolverr, you should have `COMPOSE_FILE=docker-compose.yml:flaresolverr/docker-compose.yml`

### FlareSolverr

In Prowlarr, add the FlareSolverr indexer with the URL http://flaresolverr:8191/

### SABnzbd

Enable SABnzbd by setting `COMPOSE_FILE=docker-compose.yml:sabnzbd/docker-compose.yml`. It will be accessible at `/sabnzbd`.

If that is not the case, the `url_base` parameter in `sabnzbd.ini` should be set to `/sabnzbd`.

### AdGuard Home

Set the `ADGUARD_HOSTNAME`, I chose a different subdomain to use secure DNS without the folder.

On first run, specify the port 3000 and enable listen on all interfaces to make it work with Tailscale.

If after running `docker compose up -d`, you're getting `network docker-compose-nas declared as external, but could not be found`,
run `docker network create docker-compose-nas` first.

#### Encryption

In Settings > Encryption Settings, set the certificates path to `/opt/adguardhome/certs/certs/<YOUR_HOSTNAME>.crt`
and the private key to `/opt/adguardhome/certs/private/<YOUR_HOSTNAME>.key`, those files are created by Traefik cert dumper
from the ACME certificates Traefik generates in JSON.

#### DHCP

If you want to use the AdGuard Home DHCP server, for example because your router does not allow changing its DNS server,
you will need to select the `eth0` DHCP interface matching `10.0.0.10`, then specify the 
Gateway IP to match your router address (`192.168.0.1` for example) and set a range of IP addresses assigned to local
devices.

In `adguardhome/docker-compose.yml`, set the network interface `dhcp-relay` should listen to. By default, it is set to
`enp2s0`, but you may need to change it to your host's network interface, verify it with `ip a`.

In the configuration (`adguardhome/conf/AdGuardHome.yaml`), set the DHCP options 6th key to your NAS internal IP address:
```yml
dhcp:
  dhcpv4:
    options:
      - 6 ips 192.168.0.10,192.168.0.10
```

#### Expose DNS Server with Tailscale

Based on [Tailscale's documentation](https://tailscale.com/kb/1114/pi-hole), it is easy to use your AdGuard server everywhere.
Just make sure that AdGuard Home listens to all interfaces.

## Customization

You can override the configuration of a service or add new services by creating a new `docker-compose.override.yml` file,
then appending it to the `COMPOSE_FILE` environment variable: `COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml`

[See official documentation](https://docs.docker.com/compose/extends).

For example, use a [different VPN provider](https://github.com/bubuntux/nordvpn):

```yml
version: '3.9'

services:
  vpn:
    image: ghcr.io/bubuntux/nordvpn
    cap_add:
      - NET_ADMIN               # Required
      - NET_RAW                 # Required
    environment:                # Review https://github.com/bubuntux/nordvpn#environment-variables
      - USER=user@email.com     # Required
      - "PASS=pas$word"         # Required
      - CONNECT=United_States
      - TECHNOLOGY=NordLynx
      - NETWORK=192.168.1.0/24  # So it can be accessed within the local network
```

### Optional: Using the VPN for *arr apps

If you want to use the VPN for Prowlarr and other *arr applications, add the following block to all the desired containers:
```yml
    network_mode: "service:vpn"
    depends_on:
      vpn:
        condition: service_healthy
```

Change the healthcheck to mark the containers as unhealthy when internet connection is not working by appending a URL
to the healthcheck, eg: `test: [ "CMD", "curl", "--fail", "http://127.0.0.1:7878/radarr/ping", "https://google.com" ]`

Then in Prowlarr, use `localhost` rather than `vpn` as the hostname, since they are on the same network.

## Synology Quirks

Docker compose NAS can run on DSM 7.1, with a few extra steps.

### Free Ports 80 and 443

By default, ports 80 and 443 are used by Nginx but not actually used for anything useful. Free them by creating a new task
in the Task Scheduler > Create > Triggered Task > User-defined script. Leave the Event as `Boot-up` and the `root` user,
go to Task Settings and paste the following in User-defined script:
```
sed -i -e 's/80/81/' -e 's/443/444/' /usr/syno/share/nginx/server.mustache /usr/syno/share/nginx/DSM.mustache /usr/syno/share/nginx/WWWService.mustache

synosystemctl restart nginx
```

### Install Synology WireGuard

Since WireGuard is not part of DSM's kernel, an external package must be installed for the `vpn` container to run.

For DSM 7.1, download and install the package corresponding to your NAS CPU architecture 
[from here](https://github.com/vegardit/synology-wireguard/releases).

As specified in the [project's README](https://github.com/vegardit/synology-wireguard#installation), 
the package must be run as `root` from the command line: `sudo /var/packages/WireGuard/scripts/start`

### Free Port 1900

Jellyfin will fail to run by default since the port 1900 
[is not free](https://lookanotherblog.com/resolve-port-1900-conflict-between-plex-and-synology/). 
You may free it by going to  Control Panel > File Services > Advanced > SSTP > Untick `Enable Windows network discovery`.

### User Permissions

By default, the user and groups are set to `1000` as it is the default on Ubuntu and many other Linux distributions.
However, that is not the case in Synology; the first user should have an ID of `1026` and a group of `100`. 
You may check yours with `id`. 
Update the `USER_ID` and `GROUP_ID` in `.env` with your IDs.
Not updating them may result in [permission issues](https://github.com/AdrienPoupa/docker-compose-nas/issues/10).

```
USER_ID=1026
GROUP_ID=100
```

### Synology DHCP Server and Adguard Home Port Conflict

If you are using the Synology DHCP Server package, it will use port 53 even if it does not need it. This is because
it uses Dnsmasq to handle DHCP requests, but does not serve DNS queries. The port can be released by editing (as root) 
`/usr/local/lib/systemd/system/pkg-dhcpserver.service` and [adding -p 0](https://www.reddit.com/r/synology/comments/njwdao/comment/j2d23qr/?utm_source=reddit&utm_medium=web2x&context=3):
`ExecStart=/var/packages/DhcpServer/target/dnsmasq-2.x/usr/bin/dnsmasq --user=DhcpServer --group=DhcpServer --cache-size=200 --conf-file=/etc/dhcpd/dhcpd.conf --dhcp-lease-max=2147483648 -p 0`
Reboot the NAS and the port 53 will be free for Adguard.

## Use Separate Paths for Torrents and Storage

If you want to use separate paths for torrents download and long term storage, to use different disks for example,
set your `docker-compose.override.yml` to:

```yml
version: "3.9"
services:
  sonarr:
    volumes:
      - ./sonarr:/config
      - ${DATA_ROOT}/media/tv:/data/media/tv
      - ${DOWNLOAD_ROOT}/tv:/data/torrents/tv
  radarr:
    volumes:
      - ./radarr:/config
      - ${DATA_ROOT}/media/movies:/data/media/movies
      - ${DOWNLOAD_ROOT}/movies:/data/torrents/movies
```

Note you will lose the hard link ability, ie your files will be duplicated.

In Sonarr and Radarr, go to `Settings` > `Importing` > Untick `Use Hardlinks instead of Copy`

## NFS Share

This can be useful to share the media folder to a local player like Kodi or computers in the local network,
but may not be necessary if Jellyfin is going to be used to access the media.

Install the NFS kernel server: `sudo apt install nfs-kernel-server`

Then edit `/etc/exports` to configure your shares:

`/mnt/data/media 192.168.0.0/255.255.255.0(rw,all_squash,nohide,no_subtree_check,anonuid=1000,anongid=1000)`

This will share the `media` folder to anybody on your local network (192.168.0.x).
I purposely left out the `sync` flag that would slow down file transfer.
On [some devices](https://forum.kodi.tv/showthread.php?tid=343434) you may need to use the `insecure`
option for the share to be available.

Restart the NFS server to apply the changes: `sudo /etc/init.d/nfs-kernel-server restart`

On other machines, you can see the shared folder by adding the following to your `/etc/fstab`:

`192.168.0.10:/mnt/data/media /mnt/nas nfs ro,hard,intr,auto,_netdev 0 0`

## Static IP

Set a static IP, assuming `192.168.0.10` and using Google DNS servers: `sudo nano /etc/netplan/00-installer-config.yaml`

```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp2s0:
      dhcp4: no
      addresses:
        - 192.168.0.10/24
      gateway4: 192.168.0.1
      nameservers:
          addresses: [8.8.8.8, 8.8.4.4]
  version: 2
```

Apply the plan: `sudo netplan apply`. You can check the server uses the right IP with `ip a`.

## Laptop Specific Configuration

If the server is installed on a laptop, you may want to disable the suspension when the lid is closed:
`sudo nano /etc/systemd/logind.conf`

Replace:
- `#HandleLidSwitch=suspend` by `HandleLidSwitch=ignore`
- `#LidSwitchIgnoreInhibited=yes` by `LidSwitchIgnoreInhibited=no`

Then restart: `sudo service systemd-logind restart`

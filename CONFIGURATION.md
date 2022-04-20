# Configuration

## Environment Variables

`cp .env.example .env`

then fill the `.env` file with your variables:

- `USER_ID`: ID of the user to use in Docker containers, defaults to `1000`
- `GROUP_ID`: ID of the user group to use in Docker containers, defaults to `1000`
- `TIMEZONE`: for the containers, defaults to `America/New_York`
- `DATA_ROOT`: host location of the data files, defaults to `/mnt/data`
- `DOWNLOAD_ROOT`: host download location for qBittorrent, should be a subfolder of `DATA_ROOT`, defaults to `/mnt/data/torrents`
- `PIA_LOCATION`: servers to use for PIA, defaults to `ca`, ie Montreal, Canada with port forwarding support
- `PIA_USER`: PIA username
- `PIA_PASS`: PIA password
- `PIA_LOCAL_NETWORK`: PIA local network

## PIA Wireguard VPN

I chose PIA since it supports Wireguard and [port forwarding](https://github.com/thrnz/docker-wireguard-pia/issues/26#issuecomment-868165281),
but you could use other providers:

- OpenVPN: [linuxserver/openvpn-as](https://hub.docker.com/r/linuxserver/openvpn-as)
- Wireguard: [linuxserver/wireguard](https://hub.docker.com/r/linuxserver/wireguard)
- NordVPN + OpenVPN: [bubuntux/nordvpn](https://hub.docker.com/r/bubuntux/nordvpn/dockerfile)
- NordVPN + Wireguard (NordLynx): [bubuntux/nordlynx](https://hub.docker.com/r/bubuntux/nordlynx)

For PIA + Wireguard, fill `.env` and fill it with your PIA credentials.

The location of the server it will connect to is set by `LOC=ca`, defaulting to Montreal - Canada.

## Sonarr & Radarr

### File Structure

Sonarr and Radarr must be configured to support hardlinks, to allow instant moves and prevent using twice the storage 
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
```

Go to Settings > Management.
In Sonarr, set the Root folder to `/data/media/tv`.
In Radar, set the Root folder to `/data/media/movies`.

![](https://cdn.poupa.net/uploads/2022/03/root-folder.png)

### Download Client

Then qBittorrent can be configured at Settings > Download Clients. Because all the networking for qBittorrent takes
place in the VPN container, the hostname for qBittorrent is the hostname of the VPN container, ie `vpn`, and the port is `8080`:

![](https://cdn.poupa.net/uploads/2022/03/qbittorrent.png)

## Prowlarr

The indexers are configured through Prowlarr. They synchronize automatically to Radarr and Sonarr.

Radarr and Sonarr may then be added via Settongs > Apps. The Prowlarr server is `http://prowlarr:9696/prowlarr`, the Radarr server
is `http://radarr:7878/radarr` and Sonarr `http://sonarr:8989/sonarr`:

![](https://cdn.poupa.net/uploads/2022/03/sonarr.png)

Their API keys can be found in Settings > Security > API Key.

## qBittorrent

Set the default save path to `/data/torrents` in Settings:

![](https://cdn.poupa.net/uploads/2022/03/path.png)

Restrict the network interface to Wireguard:

![](https://cdn.poupa.net/uploads/2022/03/wireguard.png)

The web UI login page can be disabled on for the local network in Settings > Web UI > Bypass authentication for clients

```
192.168.0.0/16
127.0.0.0/8
172.17.0.0/16
```

## Heimdall

Applications can be added in Items > Add. The URLs should be the static IP, ie: `http://192.168.0.10/` for Sonarr
for example.

![](https://cdn.poupa.net/uploads/2022/03/homepage.png)

# Hetzner Server Setup Guide

This guide walks you through the process of setting up a Hetzner server with Docker, configuring a Hetzner Storage Box, and running media server applications like Jellyfin, Sonarr, Radarr, and Jellyseer.

## Create Hetzner Server
1. Cloud-config for Initial Server Setup

The following cloud-config is used to set up a Hetzner server with Docker, Docker Compose, and additional security packages (like Fail2Ban):

```bash
#cloud-config
package_upgrade: true
apt:
  sources:
    docker.list:
      source: deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable
      keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-buildx-plugin
  - docker-compose-plugin
  - fail2ban
  
groups:
  - docker
  
system_info:
  default_user:
    groups: [docker]
```

2. Install Additional Kernel Modules
If additional kernel modules are needed, for example, to enable UTF-8 support, run:
```bash
sudo apt install linux-modules-extra-$(uname -r)
```

## Create Hetzner Storage box
1. Go to Hetzner Storage Box Page 
Visit: `https://www.hetzner.com/storage/storage-box/`
2. Mount the Storage box:
``` bash
mount -t cifs <username>.your-storagebox.de/backup /mnt/backup-server cifs iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,uid=<system account>,gid=<system group>,file_mode=0660,dir_mode=0770 0 0
```

To make this mount persistent across reboots, add the following line to /etc/fstab:
```bash
//<username>.your-storagebox.de/backup /mnt/backup-server cifs iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,uid=<system account>,gid=<system group>,file_mode=0660,dir_mode=0770 0 0
```

3. Additional Mount Configurations
Add these two lines to /etc/fstab to enable multiple mount points:
``` bash
//u439025.your-storagebox.de/backup /mnt/data cifs iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,file_mode=0770,dir_mode=0770,uid=1000,gid=1000 0 0
//u439025.your-storagebox.de/backup /mnt/data_nobrl cifs nobrl,iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,file_mode=0770,dir_mode=0770,uid=1000,gid=1000,vers=3.0 0 0
```
The first line is for general file storage, and the second enables write access for databases.

4. Backup Credentials File
Create the credentials file `/etc/backup-credentials.txt` (mode 0600) with the following content:
```bash
username=<username>
password=<password>
```
Then change the file's permissions to ensure security:
```bash
chmod 0600 /etc/backup-credentials.txt
```

5. Create Media Folders
```bash
mkdir -p /mnt/data/medialibrary
cd /mnt/data/medialibrary
mkdir books movies music tv
sudo chown -R 1000:1000 .
```

If the Storage Box is not mounted after a reboot, follow these troubleshooting steps:
- Manually mount the disk: `mount -a`
- Check kernel logs for errors: `dmesg | tail -n 50`


## Run applications
1. Clone Repository
Clone the docker-compose-nas repository:
```bash
https://github.com/arbupo/docker-compose-nas.git
```
2. Create Environment Variables File
Copy the sample environment file and update it with the appropriate values:
```bash
cp .env.sample .env
```
3. Run Docker Containers
Start the Docker containers in detached mode:
```bash
docker compose up -d
```

## Configure Applications

### Configure Jellyfin
1. **Login to Jellyfin**
   Access your Jellyfin instance through the web interface.
2. **Add Media Libraries**
  - Go to the Dashboard → Libraries.
  - Click Add New Library and select `Movies`. Choose `/movies` as the library path.
  - Click Add New Library again, select `TV` and choose `/tv` as the path.

### Configure Sonarr
#### Configure Root Folder:
1. **Login to Sonarr**
2. Go to *Settings* → *Media Management*.
3. In the *Root Folder* section, click *Add Root Folder*.
4. Select folder `/tv`.

#### Configure Custom Format:
1. **Login to Sonarr**
2. Go to *Settings* → *Custom Formats* and click *Add Custom Format*.
  - Name: x265
  - Conditions
    - Name: x265
    - Regular expression: x265

#### Configure Torrent Client:
1. **Login to Sonarr**
2. Go to *Settings* → *Download Clients*.
3. Click *Add Download Client* and configure the client.
  - name: qbittorrent
  - host: vpn
  - port: 8080
4. Click *Test*.
5. If successful, click *Save*.
6. After configuring the VPN and switching the network to qBittorrent, change the host from `qbittorrent` to `vpn`.

#### Limit TV Episode Size:
1. Go to `{localhost}/sonarr/settings/indexers`.
2. Set the *Maximum Size* to `3500 MB`.
3. Click *Save*.

#### Set Indexer Seed Ratio:
1. **Login to Radarr**.
2. Go to *Settings* → *Indexers*.
3. Click on each indexer and set the *Seed Ratio* to `0.00001`.

### Configure  Radarr

#### Configure Root Folder:
1. **Login to Radarr**.
2. Go to *Settings* → *Media Management*.
3. In the *Root Folder* section, click *Add Root Folder*.
4. Select folder `/movies`.

#### Configure Custom Format:
1. **Login to Radarr**.
2. Go to *Settings* → *Custom Formats*.
3. Create a *Custom Format* with the condition `Release Title` and use the regular expression `x265`.

#### Configure Torrent Client:
Follow the same steps as for Sonarr.

#### Limit TV Episode Size:
1. Go to `{localhost}/radarr/settings/indexers`.
2. Set the *Maximum Size* to `3500 MB`.
3. Click *Save*.

#### Set Indexer Seed Ratio:
1. **Login to Radarr**.
2. Go to *Settings* → *Indexers*.
3. Click on each indexer and set the *Seed Ratio* to `0.00001`.


### Configure Jellyseer
To set up Jellyseer, go to `https://hostname/jellyseerr/setup` and set the URLs as follows:

1. **Configure Jellyfin:**
   - URL: `http://jellyfin:8096/jellyfin`.

2. **Configure Radarr:**
   - Hostname: `radarr`
   - Port: `7878`
   - URL Base: `/radarr`
   - Get the *API Key* from the `.env` file.
   - Click *Test*.
   - Select Quality: `720/1080 HD`.
   - Click *Test*.
   - Select *Root Folder*: `/movies`.
   - Click *Save*.

3. **Configure Sonarr:**
   - Hostname: `sonarr`
   - Port: `8989`
   - URL Base: `/sonarr`
   - Get the *API Key* from the `.env` file.
   - Click *Test*.
   - Select Quality: `720/1080 HD`.
   - Click *Test*.
   - Select *Root Folder*: `/tv`.
   - Click *Save*.


### Configure Prowlar Indexers
1. Open Prowlar.
2. Go to *Indexers*.
3. Click *Add Indexer* and add the following:
   - Badass Torrents
   - LimeTorrents
   - YourBittorrent
   - YTS


### Configure Bazarr
1. **Login to Bazarr**.
2. Go to *Settings* → *Providers* and click the (+) button.
   - Add the following providers:
     - OpenSubtitles.com
     - YIFS Subtitles
     - TV Subtitles
     - Supersubtitles
     - Embedded Subtitles
     - Addic7ed
     - Subtitulados.tv

3. Go to *Settings* → *Languages* and add the *Language Filter*: `English`.
4. Go to *Settings* → *Languages* and add the *Language Profiler*: `English`.
5. Add Sonarr configuration.
6. Add Radarr configuration.


## Additionals  
### Get IP and location
Get Container IP:
```bash
wget -qO- ifconfig.me` # or curl ifconfig.me
```
Get Container IP and location:
``` bash
wget -qO- ipinfo.io`  # or curl ipinfo.io
```
### Check container healthstate
docker inspect --format='{{json .State.Health.Status}}' protonwire
### See qbittorrent logs
1. Access qbittorrent docker container: `docker exec -it qbittorrent sh`
2. `cd /config/qBittorrent/logs`
3. `tail -n 50 qbittorrent.log`





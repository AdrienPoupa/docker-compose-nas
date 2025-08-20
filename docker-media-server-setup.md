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

## Create mount directores
mkdir -p /mnt/data /mnt/data_nobrl

## Update ubuntu and install cifs utils
```bash
sudo apt update
sudo apt install cifs-utils
sudo apt install docker-compose
```

## Create Hetzner Storage box
1. Go to Hetzner Storage Box Page 
Visit: `https://www.hetzner.com/storage/storage-box/`
2. Mount the Storage box:
 - Test trying to access using username and password
   ```bash
   sudo mount.cifs -o user=<<username>>,pass=<<password>> //u439025.your-storagebox.de/backup /mnt/data
   ```
 - Test trying to access using credentials
   ``` bash
   mount -t cifs <username>.your-storagebox.de/backup /mnt/backup-server cifs iocharset=utf8,rw,credentials=/etc/backup-credentials.txt,uid=<system account>,gid=<system group>,file_mode=0660,dir_mode=0770 0 0
   ```
   for example
   ```bash
   sudo mount -t cifs //u439025.your-storagebox.de/backup /mnt/data -o rw,credentials=/etc/backup-credentials.txt,file_mode=0770,dir_mode=0770,uid=1000,gid=1000
   ```
- Make persistent
   To make this mount persistent across reboots, add the following line to /etc/fstab:
   ```bash
   //<username>.your-storagebox.de/backup /mnt/backup-server cifs rw,credentials=/etc/backup-credentials.txt,uid=<system account>,gid=<system group>,file_mode=0660,dir_mode=0770 0 0
   ```

3. Additional Mount Configurations
Add these two lines to /etc/fstab to enable multiple mount points:
``` bash
//u439025.your-storagebox.de/backup /mnt/data cifs rw,credentials=/etc/backup-credentials.txt,file_mode=0770,dir_mode=0770,uid=1000,gid=1000 0 0
//u439025.your-storagebox.de/backup /mnt/data_nobrl cifs nobrl,rw,credentials=/etc/backup-credentials.txt,file_mode=0770,dir_mode=0770,uid=1000,gid=1000,vers=3.0 0 0
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
5.  Run command:
   ```bash
   systemctl daemon-reload
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
- Check kernel logs for errors: `   


## Run applications
1. Create a folder
```bash
mkdir -p ~/Documents/GitHub
```
2. Clone Repository
Clone the docker-compose-nas repository:
```bash
mkdir GitHub
cd GitHub
git clone https://github.com/arbupo/docker-compose-nas.git
```
3. Create Environment Variables File
Copy the sample environment file and update it with the appropriate values:
```bash
cp .env.sample .env
```
4. Update env values
```bash
HOSTNAME="app.nosoupforyou.xyz"
DOMAIN="nosoupforyou.xyz"
LETS_ENCRYPT_EMAIL="alon.wengierko@gmail.com"
```
5. Run Docker Containers
Start the Docker containers in detached mode:
```bash
docker compose up -d
```
6. Update applicatios base URLs and set API Keys
For the first time, run `./update-config.sh` to update the applications base URLs and set the API keys in `.env`.

## Configure Applications

### Configure Jellyfin
1. **Login to Jellyfin**
   Access your Jellyfin instance through the web interface.
2. ***Set admin username/password***
3. **Add Media Libraries**
  - Go to the Dashboard → Libraries.
  - Click Add New Library and select `Movies`. Choose `/movies` as the library path.
  - Click Add New Library again, select `TV` and choose `/tv` as the path.
4. ***Create users***
  - Go to administration
  - Go to users
  - Click (+) button


### Configure VPN
Set env values for
```bash
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY="xxxxx"
SERVER_COUNTRIES="United States"
```

### Configure Qbittorrent
1. Get password from docker-compose logs
2. Login to Qbittorrent
3. Go to tools -> Options -> WebUI -> Authentication -> Change current password
4. Select *Bypass authentication for clients on localhost*
5. Select *Bypass authentication for clients in whitelisted IP subnets* and select `prowlarr, radarr, sonarr`

### Configure Prowlar
#### Configure authentication
1. **Login to Prowlarr**
2. Complete authentication configuration form:
   - Authentication Method: Forms (Login Page)
   - Authentication Required: Disabled for Local Addresses

#### Add indexers
1. **Login to Prowlarr**
2. Go to *Indexers*.
3. Click *Add Indexer* and add the following:
   - Badass Torrents
   - LimeTorrents
   - YourBittorrent
   - YTS
5. Set seed ratio to 0.001 for each indexer
6. After click Test for each indexer and then Save

#### Configure Indexers for other applications
1. **Login to Prowlarr**
2. Go to settings -> Apps -> Add Application 
3. Click Add Sonarr
4. Get API Key from .env file
5. The indexers are configured through Prowlarr. They synchronize automatically to Radarr and Sonarr.
Radarr and Sonarr may then be added via Settings > Apps. The Prowlarr server is `http://prowlarr:9696/prowlarr`, the Radarr server
is `http://radarr:7878/radarr` Sonarr `http://sonarr:8989/sonarr`, and Lidarr `http://lidarr:8686/lidarr`.
Their API keys can be found in Settings > Security > API Key.


### Configure Sonarr
#### Configure authentication
1. **Login to Sonarr**
2. Complete authentication configuration form:
   - Authentication Method: Forms (Login Page)
   - Authentication Required: Disabled for Local Addresses
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
    - Condition: Release Title
    - Name: x265
    - Regular expression: 
    - Set Required
#### Cofigure Indexers
1. It should not be neccesary, since it was configure before via prowlarr. 
#### Configure Torrent Client:
1. **Login to Sonarr**
2. Go to *Settings* → *Download Clients*.
3. Click *Add Download Client* and configure the client.
  - name: qbittorrent
  - host: vpn
  - port: 8080
  - username: configure username for qbittorrent
  - password: configure password for qbittorrent
4. Click *Test*.
5. If successful, click *Save*.
6. After configuring the VPN and switching the network to qBittorrent, change the host from `qbittorrent` to `vpn`.

#### Limit TV Episode Size:
1. Go to Settings -> indexers
1. Go to `{localhost}/sonarr/settings/indexers`.
2. Set the *Maximum Size* to `3500 MB`.
3. Click *Save Changes*.

#### Set Indexer Seed Ratio:
1. **Login to Radarr**.
2. Go to *Settings* → *Indexers*.
3. Click on each indexer and set the *Seed Ratio* to `0.00001`.

### Configure  Radarr
#### Configure authentication
1. **Login to Sonarr**
2. Complete authentication configuration form:
   - Authentication Method: Forms (Login Page)
   - Authentication Required: Disabled for Local Addresses
#### Configure Root Folder:
1. **Login to Radarr**.
2. Go to *Settings* → *Media Management*.
3. In the *Root Folder* section, click *Add Root Folder*.
4. Select folder `/movies`.
#### Configure Custom Format:
1. **Login to Radarr**.
2. Go to *Settings* → *Custom Formats*.
3. Create a *Custom Format* with the condition `Release Title` and use the regular expression `x265`.
#### Cofigure Indexers
1. It should not be neccesary, since it was configure before via prowlarr. 
#### Configure Torrent Client:
1. **Login to Sonarr**
2. Go to *Settings* → *Download Clients*.
3. Click *Add Download Client* and configure the client.
  - name: qbittorrent
  - host: vpn
  - port: 8080
  - username: configure username for qbittorrent
  - password: configure password for qbittorrent
4. Click *Test*.
5. If successful, click *Save*.
6. After configuring the VPN and switching the network to qBittorrent, change the host from `qbittorrent` to `vpn`.
#### Limit TV Episode Size:
1. Go to `{localhost}/radarr/settings/indexers`.
2. Set the *Maximum Size* to `3500 MB`.
3. Click *Save*.


### Configure Jellyseer
To set up Jellyseer, go to `https://hostname/jellyseerr/setup` and set the URLs as follows:

1. **Configure Server Type:**
   - URL: `http://jellyfin:8096/jellyfin`.
   - Jellyfin URL: jellyfin
   - Jellyfin Port: 8096
   - Jellyfin URL Base: jellyfin
   - Jellyfin username:
   - Jellyfin password: 
2. **Sign In**
   - Set Jellyfin libraries
   - Click manual library sync
3. **Configure Radarr:**
   - Default Service: yes
   - Hostname: `radarr`
   - Port: `7878`
   - URL Base: `/radarr`
   - Get the *API Key* from the `.env` file.
   - Click *Test*.
   - Select Quality: `720/1080 HD`.
   - Click *Test*.
   - Select *Root Folder*: `/movies`.
   - Click *Save*.
4. **Configure Sonarr:**
   - Default Service: yes
   - Hostname: `sonarr`
   - Port: `8989`
   - URL Base: `  `
   - Get the *API Key* from the `.env` file.
   - Click *Test*.
   - Select Quality: `720/1080 HD`.
   - Click *Test*.
   - Select *Root Folder*: `/tv`.
   - Click *Save*.
5. **Create users**
   - Import from Jellyfin
   - Configure settings to auto approve


### Configure Bazarr 
1. **Login to Bazarr**.
2. Go to *Settings* → *Providers* and click the (+) button.
   - Add the following providers:
     - OpenSubtitles.com
     - YIFY Subtitles
     - TVSubtitles
     - Supersubtitles
     - Embedded Subtitles
     - Addic7ed
     - Subtitulados.tv
   - Click Save

3. Go to *Settings* → *Languages* and add the *Language Filter*: `English`.
4. Go to *Settings* → *Languages* and add the *Language Profiler*: `English`.
5. Add Sonarr configuration.
6. Add Radarr configuration.

### Configure Cabernet

1. **Login to Cabernet**.  
   - Open your browser and go to: `http://cabernet.{hostname}`  

2. **Install the M3U Plugin**.  
   - Go to *Plugins* → *Catalog*.  
   - Find **M3U**, click on it, then click the **hamburger menu** button and select **Install Plugin**.  

3. **Update Configuration File**.  
   - Edit the `config.ini` file located at: `cabernet/data/config.ini`  
   - Add the following configuration:  

   ```ini
   [m3u_plutotv]
   label = M3U PlutoTV US
   channel-m3u_file = http://iptv-app:4242/PlutoTV/us/name.m3u
   epg-xmltv_file = https://i.mjh.nz/PlutoTV/us.xml
   enabled = True
   channel-group_name = plutotv
   player-enable_pts_resync = True
   channel-import_groups = True
   epg-min_refresh_rate = 3600
   ```
4. **Restart Cabernet**.
   - Restart Cabernet via its web interface.
5. **Refresh Channels and EPG**.
   - Go to Functions → Scheduled Tasks and:
     - Click Refresh Channels under Channels.
     - Click Refresh EPG under EPG.
6. **Verify Channels**.
   - Go to XML/JSON Links and check `channels.m3u`.
   - Ensure it has pulled the correct channels.
7. **Login to Jellyfin**. 
   - Open your browser and go to: `http://{hostname}/jellyfin`
8. **Add M3U Tuner in Jellyfin**.
   - Go to *Dashboard* → *Live TV* → *Add Tuner Devices*.
   - Select tuner type: *M3U Tuner*.
   - Enter the URL: `http://cabernet:6077/channels.m3u` and click Save.
9. **Add XMLTV Guide Data in Jellyfin.**
   - Go to *Live TV* → *Add TV Guide Data Providers*.
   - Select XMLTV.
   - Enter the URL: `http://cabernet:6077/xmltv.xml` and click Save.


### Configure Beszel

1. **Login to Beszel**.  
   - Open your browser and go to: `http://beszel.{hostname}`  

2. **Add beszel agent**.  
   - Go to *Add System*
   - Copy the *Public Key* and update your .env file by adding:
   ```bash
   BESZEL_KEY=<your_public_key>
   ```
   - Fill out the form with the following details:
      - Name: `Docker containers`
      - Host: `beszel-agent`
      - Port: `45876`


### Configure Loki
1. **Pre-requisities**
      ##### Installing Docker Plugins for Loki
      To efficiently send logs from your Docker containers to Loki for monitoring and analysis, you'll need to install the Docker plugin for Loki. This plugin acts as a log driver for Docker and ensures that container logs are directed to Loki.

      1. ***Install Docker Plugin***
      To start using Loki with Docker, install the Grafana Loki Docker driver. Run the following command in your terminal:
      ```bash
      docker plugin install grafana/loki-docker-driver:2.9.1 --alias loki --grant-all-permissions
      ```
      2. ***Configure Docker Daemon***
      Next, configure Docker to use the Loki log driver by modifying the daemon.json file, which is Docker's configuration file. This step is necessary to direct container logs to Loki.
         - Open the `/etc/docker/daemon.json` file on your system.
         - Paste the following configuration:
      ```json
      {
      "log-driver": "loki",
      "log-opts": {
         "loki-url": "http://localhost:3100/loki/api/v1/push",
         "loki-batch-size": "400"
      }
      }
      ```
   
      ```json
      {
      "log-driver": "loki",
      "log-opts": {
         "mode":"non-blocking",
         "loki-url": "http://localhost:3100/loki/api/v1/push", 
         "loki-batch-size": "400",
         "loki-retries": "2",
         "loki-max-backoff":"800ms",
         "loki-timeout":"1s"
      }
      }
      ```
      ```json
      {
      "log-driver": "loki",
      "log-opts": {
         "mode": "non-blocking",
         "loki-url": "http://localhost:3100/loki/api/v1/push",
         "loki-batch-size": "400",
         "loki-retries": "2",
         "loki-max-backoff": "800ms",
         "loki-timeout": "1s",
         "loki-batch-wait": "1s",
         "max-line-size": "1k",
         "labels": {
            "app": "myapp",
            "env": "production"
         }
      },
      "http-timeout": "200s",
      "log-level": "info",
      "data-root": "/mnt/docker-data",
      "default-address-pools": [
         {"base": "192.168.0.0/16", "size": 24}
      ],
      "userns-remap": "default",
      "dns": ["8.8.8.8", "8.8.4.4"]
      }
      ```


      3. ***Restart Docker***
      Once you have updated the configuration file, you need to restart Docker for the changes to take effect. You can restart Docker with the following command:
      ```bash
      sudo systemctl restart docker
      ```

      The Docker plugin enables seamless integration between Docker containers and Loki for centralized log management.

      ##### Checking Loki Access for Labels, Metrics and queries
      1. ***Query Logs:***
      ```bash
      https://{loki_subdomain}.{domain}/loki/api/v1/query_range?query={job=%22docker%22}&start=1609459200000000000&end=1609462800000000000
      ```
      2. ***Metrics for Health Check:***
      ```bash
      https://{loki_subdomain}.{domain}/metrics
      ```
      3. ***Query Labels:***
      ```bash
      https://{loki_subdomain}.{domain}/loki/api/v1/labels
      ```

      ##### ***Ping, Curl and Wget Commands**
      If using promtail, access promtail docker container and run one of the following commandas:
      ```bash
      ping loki
      curl -s http://loki:3100/loki/api/v1/labels
      wget -qO- http://loki:3100/loki/api/v1/labels
      ```

### Configure Prometheus


### Configure Grafana Cloud
#### Add a New Loki Data Source in Grafana
   1. **Open Grafana**
   - Log in to your **Grafana** instance.
   - Click on the **Gear Icon (⚙️) → Data Sources**.

   2. **Add a New Data Source**
   - Click **"Add data source"**.
   - Search for **"Loki"** and select it.

   3. **Configure Loki Data Source**
   - In the **URL** field, enter:
   ``` bash
   http://your-loki-server:3100
   ```
   (Replace `your-loki-server` with your actual Loki server address.)
   e.g could be `https://loki.myapp.com`

   - Enable **Basic Auth**
   - Enter your **Grafana Cloud username & API key**

   4. **Save & Test**
   - Click **"Save & Test"**.
   - If successful, you’ll see a message:  
   ✅ **Data source is working**

   5. **Query Logs**
   - Go to **"Explore" (Compass Icon 🧭)**.
   - Select **Loki** as the data source.
   - Run queries like:
   ```logql
   {job="your-app"}
   ```

#### Add a New Prometheus Data Source in Grafana

1. **Open Grafana**
- Log in to your **Grafana** instance.
- Click on the **Gear Icon (⚙️) → Data Sources**.

2. **Add a New Data Source**
- Click **"Add data source"**.
- Search for **"Prometheus"** and select it.

3. **Configure Prometheus Data Source**
- In the **URL** field, enter:
```bash
http://your-prometheus-server:9090
```
(Replace your-prometheus-server with your actual Prometheus server address.)
e.g., could be `https://prometheus.myapp.com`

- Enable **Basic Auth**
- Enter your **Grafana Cloud username & API key**

4. **Save & Test**
- Click **"Save & Test"**.
- If successful, you’ll see a message:  
✅ **Data source is working**

5. **Query Metrics**
- Go to **"Explore" (Compass Icon 🧭)**.
- Select **Prometheus** as the data source.
- Run queries like:
```promql
node_cpu_seconds_total
```


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
### Viewing Traefik Logs for Invalid Certificate Issues

To monitor Traefik logs and identify invalid certificate errors, follow these steps:

1. **Open a terminal and run the following command:**  
   ```bash
   docker logs -f traefik
   ```
   - The -f flag ensures live log streaming.
   - Look for SSL/TLS errors related to certificate validation.

2. **Filter logs for SSL-related messages (optional):**
   ```bash
   docker logs -f traefik | grep -i "certificate"
   ```

3. **Check the Traefik dashboard or logs for details on the invalid certificate issue.**

### Additional Network and Container Checks
To inspect network settings and container health, use the following Docker commands:
```bash
docker network inspect docker-compose-nas # inspect network ips
```
Inspect an specific container
```bash
docker inspect radarr
```

If get error, when trying to run immich, try creating missing folders and missing .immich files.

Add authentication to bazarr

Add Default Language Profiles For Newly Added Shows
If you have previous movies, series, do a mass edit of the language profile

Check where is pointing
nslookup traefik.nosoupforyou.xyz

#### Fix values in homepage
Create jellyfin api key
1. Login to jellyfin -> advanced -> api keys. -> +  -> Copy and update .env vlaues
Create audiobookshelf api key
1. Login to abs -> settings -> API Keys -> Add API key for homepage -> Copy and update .env vlaue
Create beszel username
1. Login to beszel users, use admin user, create user using command line
docker exec beszel /beszel superuser create username password
add username password to .env file BESZEL_USERNAME, BESZEL_PASSWORD
Create portainer api key
1. Login to portainer -> Users -> Scroll down until finding api keys -> Create api key introuce passowrd. 
The default environment is 1, so to get the used environment is to call 

`curl -L -k -H 'X-Api-Key:ptr_a_key' 'https://portainer.aloni.site/api/endpoints/3/docker/containers/json'`
where 3 is the environment. So you should try until you get a response

traefik
Create username password
htpasswd -nb <username> <password>
add to TRAEFIK_FRONTEND_AUTH
when creating hasshed password: Make sure to have a hashed password and in docker-compose.yml every single $ is escaped to $$.

Create vikunja api key
1. Create user, Go to settings, api keys, set permission, and update VIKUNJA_API_KEY

Create jellyseer
Get api key and update .env file

Set admin_token vaultwarden
echo -n "MySecretPassword" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4


# Issue with network
docker network rm docker-compose-nas
docker compose down
docker compose up -d

# Set user, group and permissions
This is important, because if this is wrong, it will not work.
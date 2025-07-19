## How to setup my servarr stack (using ProtonVPN with wireguard and automatic portforwarding)

Navigate into docker directory
```bash
cd /docker
```

Create new directory 'servarr'
```bash
mkdir servarr
```

Navigate into servarr directory
```bash
cd servarr
```

```bash
sudo nano compose.yaml
```


### compose.yaml
```bash
networks:
  servarrnetwork:
    name: servarrnetwork
    ipam:
      config:
        - subnet: 172.39.0.0/24

services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.2
    ports:
      - 8080:8080 # qbittorrent web interface
      - 6881:6881 # qbittorrent torrent port
      - 6789:6789 # nzbget
      - 9696:9696 # prowlarr
    volumes:
      - ./gluetun:/gluetun
    env_file:
      - .env
    environment:
      - VPN_SERVICE_PROVIDER=protonvpn
      - VPN_TYPE=${VPN_TYPE}
      - TZ=${TZ}
      - SERVER_COUNTRIES=${SERVER_COUNTRIES}
      - UPDATER_PERIOD=24h
      - BLOCK_MALICIOUS=off
      - PORT_FORWARD_ONLY=on
      - VPN_PORT_FORWARDING=on
      # Port forwarding up command for qBittorrent automation
      - VPN_PORT_FORWARDING_UP_COMMAND=/bin/sh -c 'wget -O- --retry-connrefused --post-data "json={\"listen_port\":{{PORTS}}}" http://127.0.0.1:8080/api/v2/app/setPreferences 2>&1'
      # ProtonVPN - OpenVPN
      # - OPENVPN_USER=${OPENVPN_USER}
      # - OPENVPN_PASSWORD=${OPENVPN_PASSWORD}
      # - OPENVPN_CIPHERS=AES-256-GCM
      # ProtonVPN - Wireguard
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
    healthcheck:
      test: ping -c 1 www.google.com || exit 1
      interval: 20s
      timeout: 10s
      retries: 5
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    labels:
      - deunhealth.restart.on.unhealthy=true
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - WEBUI_PORT=8080
      - TORRENTING_PORT=${FIREWALL_VPN_INPUT_PORTS}
    volumes:
      - ./qbittorrent:/config
      - /data:/data
    depends_on:
      gluetun:
        condition: service_healthy
        restart: true
    network_mode: service:gluetun
    healthcheck:
      test: ping -c 1 www.google.com || exit 1
      interval: 60s
      retries: 3
      start_period: 20s
      timeout: 10s

  deunhealth:
    image: qmcgaw/deunhealth
    container_name: deunhealth
    network_mode: "none"
    environment:
      - LOG_LEVEL=info
      - HEALTH_SERVER_ADDRESS=127.0.0.1:9999
      - TZ=${TZ}
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  nzbget:
    image: lscr.io/linuxserver/nzbget:latest
    container_name: nzbget
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./nzbget:/config
      - /data:/data
    depends_on:
      gluetun:
        condition: service_healthy
        restart: true
    restart: unless-stopped
    network_mode: service:gluetun

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./prowlarr:/config
    restart: unless-stopped
    depends_on:
      gluetun:
        condition: service_healthy
        restart: true
    network_mode: service:gluetun

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    restart: unless-stopped
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./sonarr:/config
      - /data:/data
    ports:
      - 8989:8989
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.3

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    restart: unless-stopped
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./radarr:/config
      - /data:/data
    ports:
      - 7878:7878
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.4

  lidarr:
    container_name: lidarr
    image: lscr.io/linuxserver/lidarr:latest
    restart: unless-stopped
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./lidarr:/config
      - /data:/data
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    ports:
      - 8686:8686
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.5

  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    restart: unless-stopped
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./bazarr:/config
      - /data:/data
    ports:
      - 6767:6767
    networks:
      servarrnetwork:
        ipv4_address: 172.39.0.6
```

### .env
```bash
# User and timezone
TZ=Europe/Copenhagen
PUID=1000
PGID=1000

# VPN Provider and protocol
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=wireguard

# Your actual port, forwarded via ProtonVPN's dashboard
FIREWALL_VPN_INPUT_PORTS=40987

# Server selection
SERVER_COUNTRIES=Denmark

# ProtonVPN - Wireguard key (from your config)
WIREGUARD_PRIVATE_KEY=your_private_key

# (Optional) Advanced: If you want to override the default Wireguard address/DNS, uncomment these:
# WIREGUARD_ADDRESSES=10.2.0.2/32
# WIREGUARD_DNS=10.2.0.1

# -----------------------------
# OpenVPN - commented out since not used
# OPENVPN_USER=your_protonvpn_username
# OPENVPN_PASSWORD=your_protonvpn_password
# OPENVPN_CIPHERS=AES-256-GCM
```

In the servarr directory, run the following command
```bash
docker compose up -d
```

When everything is up and running, your directory should look like this:
```bash
docker
├── jellyfin
│   ├── config
│   └── jellyseerr
└── servarr
    ├── bazarr
    ├── gluetun
    ├── lidarr
    ├── nzbget
    ├── prowlarr
    ├── qbittorrent
    ├── radarr
    └── sonarr
```

Check by running the following commands
```bash
sudo apt install tree
```

```bash
tree /docker -d -L 2
```





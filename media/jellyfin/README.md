# How I set up Jellyfin with hardware transcoding on Nvidia GPU

Step 1 is to follow this video https://www.youtube.com/watch?v=Vwtx_dfYrtA

However, come here for commands. I'll explain when there are changes due to using an Nvidia GPU. 

In you preferred terminal

```bash
ssh your_username@your_servers_ip
```

```bash
sudo apt update && sudo apt upgrade
```

```bash
sudo reboot
```

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
```

```bash
sudo sh get-docker.sh
```

```bash
sudo usermod -aG docker $USER
```

```bash
newgrp docker
```

```bash
ll /dev/dri
```

```bash
sudo usermod -aG render your_username
```

Make sure you are in the root
```bash
cd /
```

```bash
sudo mkdir data
```

```bash
sudo mkdir docker
```

We will want to give our user full permission to read and write in these two directories. 
First check what uid and gid your user is
```bash
id
```

If it is 1000 you do not need to change anything in these commands. Otherwise change out the first 1000 with your uid, and the second 1000 with your gid
```bash
sudo chown -R 1000:1000 /data
```

```bash
sudo chown -R 1000:1000 /docker
```

```bash
sudo apt install cifs-utils
```

```bash
sudo nano /etc/fstab
```

Make sure to fill in your information, including the uid and gid if it was not 1000. 
Then paste it in the file. 
```bash
# Remote Shares
//your_media_server_ip_address_from_the_first_video/data /data cifs uid=1000,gid=1000,username=your_username,password=your_password,iocharset=utf8 0 0
```
FYI nano is an editor. ^ means CTRL. It took me an embarrassingly long time to figure out because ^ is usually SHIFT, right? 

Save the file with CTRL+O followed by ENTER to confirm the name. Close the file with CTRL+X. 

```bash
sudo systemctl daemon-reload
```

```bash
sudo mount -a
```


### This is specific to a Nvidia GPU

Check your OS and Version
```bash
cat /etc/os-release
```
As of writring this newer ubuntu versions are not supported by Nvidia so just use 22.04 if you have trouble
```bash
distribution=ubuntu22.04
```

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
```

```bash
curl -s -L https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list | \
  sed 's#deb #deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] #' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

```bash
sudo apt-get update
```

```bash
sudo apt-get install -y nvidia-container-toolkit
```

```bash
sudo systemctl restart docker
```

```bash
sudo nano /etc/docker/daemon.json
```

Paste this into the new file. If there’s already other stuff in the file, just add this runtimes block inside the top-level {}.
```json
{
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```
Save the file with CTRL+O followed by ENTER to confirm the name. Close the file with CTRL+X. 

```bash
sudo systemctl restart docker
```

Test your Nvidia runtime in Docker. You should see your GPU details.
```bash
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

Navigate to the jellyfin directory. 
```bash
cd /docker/jellyfin/
```

If you have not created the jellyfin directory yet, do so now.
```bash
cd /
cd docker
mkdir jellyfin
cd jellyfin
```

Write this command to check your user_id and group_id. If it is not 1000 and 1000, then you need to write them down.
```bash
id
```

Write this command to check your servers ip address. Write it down.
```bash
ip a
```

```bash
sudo nano compose.yaml
```

Before pasting this. Make sure to change the PUID and PGID if your IDs were not 1000, and to change the timezone, and to fill in your servers ip address. 
```bash
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Copenhagen
      - JELLYFIN_PublishedServerUrl=http://192.168.10.250
    volumes:
      - ./config:/config
      - /data:/data
    ports:
      - 8096:8096
      - 7359:7359/udp
      - 1900:1900/udp
    restart: unless-stopped
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  jellyseerr:
    container_name: jellyseerr
    image: fallenbagel/jellyseerr:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Copenhagen
    volumes:
      - ./jellyseerr:/app/config
    ports:
      - 5055:5055
    restart: unless-stopped
```
Save the file with CTRL+O followed by ENTER to confirm the name. Close the file with CTRL+X. 

```bash
docker compose up
```

Now go to your browser and put in the url 
```url
http://your_server_ip_address:8096
```

If it launches, then go back to the terminal and press CTRL+C to stop the service. 
We will need to run it in detached mode. 
```bash
docker compose up -d
```

This command allows you to monitor the GPU usage. In Jellyfin: Dashboard → Playback → Transcoding. Then try playing a movie that needs transcoding. 
```bash
watch nvidia-smi
```


🚀


Next steps is setting up the servarr stack
https://github.com/emmyapi/homelab/tree/main/media/servarr



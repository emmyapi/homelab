# How I set up Jellyfin with hardware transcoding on Nvidia GPU

Step 1 is to follow this video https://www.youtube.com/watch?v=Vwtx_dfYrtA

However, come here for commands. I'll explain when there are changes sue to using an Nvidia GPU. 

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

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

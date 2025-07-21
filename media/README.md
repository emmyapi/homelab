## Start with jellyfin and move to servarr afterwards

Jellyfin-directory holds a good amount of general information on how to setup an ubuntu server and passing through your Nvidia GPU, before setting up jellyfin.

Servarr-directory then builds all the services for a full Servarr setup. 



Maintenance: 

Originally I assigned the Servarr VM too many resources. I have reduced it to only 4 GB memory and 2 cores. Originally it was 8GB/6 cores. 
After making the change I booted the device and it couldn't find my GPU. So I re-added it, and suddenly it couldn't boot. 

I rebooted the pve, made sure the Servarr was shutdown, and then in the pve shell I pasted the following: 

```bash
nano /etc/pve/qemu-server/101.conf
```

I cleaned up the file so that my GPU where only added once, and made sure video and audio were named correctly. 

```bash                                                    
boot: order=scsi0;net0
cores: 2
cpu: x86-64-v2-AES
hostpci0: 0000:01:00.0
hostpci1: 0000:01:00.1
memory: 4096
...
...
...
```

I started the Servarr and ran 

```bash
sudo apt update && sudo apt upgrade -y
```

I shut down and turned all the docker compose containers on again. 

Then I ran neofetch to see a few stats
```bash
neofetch
```

I ran free -h to see the memory
```bash
free -h
```

Lastly I ran htop to monitor the usage while I played a high quality video file transcoding with dolby vision. 
```bash
htop
```

The stats did not move. It is now much leaner and it doesn't even feel different in use. Just be aware you might run into issues if you have a lot of users. But we never run more than one instance at the same time. 

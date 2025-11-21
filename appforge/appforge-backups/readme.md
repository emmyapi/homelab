# Restic infrastructure

## Environment variables
kenneth@appforge:~$ sudo ls -la /root
-rw-------  1 root root  179 Nov 17 06:47 .restic-appforge.env
-rw-------  1 root root  181 Nov 17 06:53 .restic-bitwarden.env
-rw-------  1 root root  171 Nov 21 14:22 .restic-totp.env
-rw-------  1 root root  177 Nov 17 06:51 .restic-valheim.env (one per valheim world)


## Script
kenneth@appforge:~$ sudo ls -la /usr/local/bin
-rwxr-xr-x  1 root root 2272 Nov 17 06:58 backup-appforge.sh
-rwxr-xr-x  1 root root 2545 Nov 21 16:11 backup-bitwarden.sh
-rwxr-xr-x  1 root root 2709 Nov 21 15:44 backup-totp.sh
-rwxr-xr-x  1 root root 3227 Nov 21 16:11 backup-valheim.sh


## Service and timer
kenneth@appforge:~$ sudo ls -la /etc/systemd/system
-rw-r--r--  1 root root  240 Nov 17 07:20 backup-appforge.service
-rw-r--r--  1 root root  140 Nov 21 07:28 backup-appforge.timer
-rw-r--r--  1 root root  239 Nov 17 07:21 backup-bitwarden.service
-rw-r--r--  1 root root  131 Nov 21 07:29 backup-bitwarden.timer
-rw-r--r--  1 root root  236 Nov 21 14:26 backup-totp.service
-rw-r--r--  1 root root  138 Nov 21 14:26 backup-totp.timer
-rw-r--r--  1 root root  235 Nov 17 07:20 backup-valheim.service
-rw-r--r--  1 root root  136 Nov 21 07:28 backup-valheim.timer


## Password
kenneth@appforge:~$ sudo ls -la /root/.config/restic
-rw------- 1 root root   10 Nov 17 06:27 appforge-password.txt


## Cache
kenneth@appforge:~$ sudo ls -la /var/cache/restic
drwxr-xr-x  3 root root 4096 Nov 17 06:53 appforge
drwxr-xr-x  3 root root 4096 Nov 17 06:53 bitwarden
drwxr-xr-x  3 root root 4096 Nov 21 15:08 totp
drwxr-xr-x  4 root root 4096 Nov 19 14:16 valheim


## Backup Destination
kenneth@appforge:~$ ls -la /mnt/appforge-backups
drwxr-xr-x 7 root root    8 Nov 17 06:48 appforge
drwxr-xr-x 7 root root    8 Nov 17 06:53 bitwarden
drwxr-xr-x 7 root root    9 Nov 21 13:59 totp
drwx------ 7 root root    8 Nov 19 14:15 valheim


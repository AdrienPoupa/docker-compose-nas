# Installation

## Requirements

Any Docker-capable recent Linux box. 
I am using a fresh Ubuntu Server 20.04 on a repurposed laptop so this guide reflects it, 
but it would  probably work with other distributions and different versions with a few tweaks.

## Pre-Docker Steps

### OpenSSH

If not done during installation, install OpenSSH server for remote connection: `sudo apt install openssh-server`

### Static IP

Set a static IP:

`sudo nano /etc//netplan/00-installer-config.yaml`

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

Here, `192.168.0.10` is going to be the static IP, and we will use Google's DNS servers. Apply the plan:

`sudo netplan apply`

You can check the server uses the right IP with `ip a`.

### Laptop Specific Configuration

If the server is installed on a laptop, you may want to disable the suspension when the lid is closed:

`sudo nano /etc/systemd/logind.conf`

Replace: 
- `#HandleLidSwitch=suspend` by `HandleLidSwitch=ignore`
- `#LidSwitchIgnoreInhibited=yes` by `LidSwitchIgnoreInhibited=no`

Then restart: `sudo service systemd-logind restart`

## Docker Setup

Install Docker by following [these instructions](https://docs.docker.com/engine/install/ubuntu/).

Then, [install Compose V2](https://docs.docker.com/compose/cli-command/#install-on-linux).

For a global installation (both your current user and `root` when using `sudo`),
copy `/usr/libexec/docker/cli-plugins` rather than `$HOME/.docker/cli-plugins/docker-compose`.

You may then run the applications with `sudo docker compose up -d`

## NFS Share

It is now time to share the folders to other local devices using NFS, as it is easy to set up and fast. 
Install the NFS kernel server:

`sudo apt-get install nfs-kernel-server`

Then edit `/etc/exports` to configure your shares:

`/mnt/data/media 192.168.0.0/255.255.255.0(rw,all_squash,nohide,no_subtree_check,anonuid=1000,anongid=1000)`

This will share the `media` folder to anybody on your local network (192.168.0.x). 
I purposely left out the `sync` flag that would slow down file transfer. 
On [some devices](https://forum.kodi.tv/showthread.php?tid=343434) you may need to use the `insecure` option for the share to be available.

Restart the NFS server to apply the changes: `sudo /etc/init.d/nfs-kernel-server restart`

On other machines, you can see the shared folder by adding the following to your `/etc/fstab`:

`192.168.0.10:/mnt/data/media /mnt/nas nfs ro,hard,intr,auto,_netdev 0 0`

## References

- [NFS setup](https://askubuntu.com/a/7124)
- [Hardlinks and Instant Moves (Atomic-Moves)](https://trash-guides.info/Hardlinks/Hardlinks-and-Instant-Moves/)

<div align="center">

<img src="./docs/logo.svg" alt="restic-nas-backup logo" width="140">

# restic-nas-backup

**Automatically mirror a Restic repository to a NAS with systemd.**

[![GitHub Pages](https://github.com/AnARCHIS12/restic-nas-backup/actions/workflows/pages.yml/badge.svg)](https://github.com/AnARCHIS12/restic-nas-backup/actions/workflows/pages.yml)
[![Platform](https://img.shields.io/badge/platform-Linux-111318?logo=linux&logoColor=white)](https://www.linux.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-111318?logo=docker&logoColor=white)](https://www.docker.com/)
[![Restic](https://img.shields.io/badge/backup-Restic-cc0000?logo=files&logoColor=white)](https://restic.net/)
[![NAS](https://img.shields.io/badge/storage-SMB%2FCIFS-111318?logo=server&logoColor=white)](https://en.wikipedia.org/wiki/Server_Message_Block)

[**Documentation**](https://anarchis12.github.io/restic-nas-backup/) · [**Installation**](https://anarchis12.github.io/restic-nas-backup/installation.html) · [**Restoration**](https://anarchis12.github.io/restic-nas-backup/restauration.html)

</div>

## Overview

`restic-nas-backup` mirrors an existing Restic repository to a NAS share using `rsync` and systemd.

```
/srv/rest-server/data/
        |
        | rsync
        v
/mnt/restic/
        |
        | SMB/CIFS
        v
NAS
```

The service stops `rest-server` during the copy and starts it again when the synchronization finishes.

The supplied timer runs every day at **13:00**, using the server's local timezone.

## What it provides

- Daily systemd scheduling at 13:00
- SMB/CIFS NAS support
- Configurable NAS IP and share
- Safety checks before writing to the destination
- Automatic stop/start of the Rest Server container
- Locking against concurrent runs
- Simple restoration helper

## Security

Never commit:

- Restic repository data
- Restic keys or repository passwords
- SMB credential files
- private IP addresses or internal network details

The public repository contains generic scripts and configuration examples only.

## Requirements

- Linux with systemd
- Docker
- `rest-server` running in a Docker container
- `rsync`
- An SMB/CIFS NAS share

## NAS mount

Example:

```fstab
//NAS_IP/Restic /mnt/restic cifs credentials=/root/.smb-restic,vers=3.0,sec=ntlmssp,_netdev,nofail,x-systemd.automount 0 0
```

Keep the actual NAS address and credentials on the server.

Verify the mount:

```bash
findmnt /mnt/restic
```

It must show the expected CIFS share.

## Installation

```bash
git clone https://github.com/AnARCHIS12/restic-nas-backup.git
cd restic-nas-backup
sudo ./install.sh
```

Edit the local configuration:

```bash
sudo nano /etc/restic-nas-sync.conf
```

Example:

```bash
RESTIC_DATA="/srv/rest-server/data"
MOUNT_POINT="/mnt/restic"
NAS_IP="NAS_IP_DU_NAS"
NAS_SHARE="Restic"
REST_SERVER_CONTAINER="rest-server"
RSYNC_OPTIONS="-aHAX --numeric-ids --delete-delay"
```

If the NAS address changes, update only `NAS_IP` in the local configuration and make the corresponding change to your SMB mount configuration.

## Test

```bash
findmnt /mnt/restic
sudo systemctl start restic-nas-sync.service
sudo journalctl -u restic-nas-sync.service -n 100 --no-pager
```

Check the timer:

```bash
systemctl list-timers restic-nas-sync.timer
```

## Restore

List snapshots from the NAS copy:

```bash
sudo restic -r /mnt/restic snapshots
```

Restore using the helper:

```bash
sudo /usr/local/sbin/restic-restore.sh
```

By default, the helper restores to:

```
/restore
```

Or specify a target and snapshot ID:

```bash
sudo /usr/local/sbin/restic-restore.sh /restore 12345678
```

The Restic repository password is still required.

## Manual controls

Start a synchronization immediately:

```bash
sudo systemctl start restic-nas-sync.service
```

Follow logs:

```bash
sudo journalctl -u restic-nas-sync.service -f
```

Disable the daily timer:

```bash
sudo systemctl disable --now restic-nas-sync.timer
```

Re-enable it:

```bash
sudo systemctl enable --now restic-nas-sync.timer
```

## Documentation

The full documentation is available on GitHub Pages:

https://anarchis12.github.io/restic-nas-backup/

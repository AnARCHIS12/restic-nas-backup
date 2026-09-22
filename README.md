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

The backup schedule is configurable by day and time and uses the server's local timezone.

## What it provides

- Configurable systemd scheduling
- SMB/CIFS NAS support
- Configurable NAS IP and share
- Safety checks before writing to the destination
- Automatic stop/start of the Rest Server container
- Locking against concurrent runs
- Simple snapshot restoration helper
- **Full Restic repository recovery from the NAS copy**
- Unified `restic-nas` CLI
- Optional secure web administration GUI *(in development — not yet available)*

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
NAS_IP="NAS_IP"
NAS_SHARE="Restic"
REST_SERVER_CONTAINER="rest-server"
RSYNC_OPTIONS="-aHAX --numeric-ids --delete-delay"

BACKUP_TIME="13:00"
BACKUP_DAYS="Mon..Sun"
```

`BACKUP_TIME` uses 24-hour `HH:MM` format. `BACKUP_DAYS` accepts systemd calendar day expressions such as `Mon..Sun` or `Mon,Wed,Fri`.

## Scheduling

View the current schedule:

```bash
sudo restic-nas schedule
```

Change it without editing systemd files:

```bash
sudo restic-nas schedule set Mon..Sun 13:00
sudo restic-nas schedule set Mon,Wed,Fri 03:30
```

The command updates the local configuration, reloads systemd and restarts the timer.

Check the timer:

```bash
systemctl list-timers restic-nas-sync.timer
```

The schedule follows the server's timezone.

## Test

```bash
sudo restic-nas backup
sudo journalctl -u restic-nas-sync.service -n 100 --no-pager
```

## Unified CLI

```bash
sudo restic-nas help
sudo restic-nas backup
sudo restic-nas restore
sudo restic-nas restore /restore 12345678
sudo restic-nas restore-repository
sudo restic-nas verify
sudo restic-nas status
sudo restic-nas schedule
sudo restic-nas schedule set Mon,Wed,Fri 03:30
```

## Restore files from a snapshot

List snapshots from the NAS copy:

```bash
sudo restic -r /mnt/restic snapshots
```

Or use the helper:

```bash
sudo restic-nas restore
```

By default, the helper restores to `/restore`.

The Restic repository password is still required.

## Full repository recovery

If the local Restic repository at `/srv/rest-server/data` is lost or needs to be replaced by the NAS mirror:

```bash
sudo restic-nas restore-repository
```

The command:

1. Verifies that `/mnt/restic` is the expected NAS share.
2. Checks that the NAS contains the expected Restic repository structure.
3. Requires you to type `RESTORE` before making changes.
4. Stops the `rest-server` container if it is running.
5. Mirrors the NAS repository back to `/srv/rest-server/data/`.
6. Deletes local repository files that are not present in the NAS copy.
7. Restarts `rest-server` when finished.

This restores the **Restic repository itself**, rather than merely extracting files from one snapshot.

> The recovery command does not reinstall Debian, Docker, or other system software. It restores the repository data used by `rest-server`.

## Manual controls

```bash
sudo systemctl start restic-nas-sync.service
sudo journalctl -u restic-nas-sync.service -f
sudo systemctl disable --now restic-nas-sync.timer
sudo systemctl enable --now restic-nas-sync.timer
```

## Web GUI *(In development — not yet available)*

> [!NOTE]
> The web administration interface is currently **in development** and **not yet available**.
> All backup, restore, and scheduling workflows are fully supported and automated via the `restic-nas` CLI and systemd.

## Documentation

The full documentation is available on GitHub Pages:

https://anarchis12.github.io/restic-nas-backup/

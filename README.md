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
- Simple snapshot restoration helper
- **Full Restic repository recovery from the NAS copy**

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

## Unified CLI

The project also provides a single command for the main backup and recovery operations:

```bash
sudo restic-nas help
```

Examples:

```bash
sudo restic-nas backup
sudo restic-nas restore
sudo restic-nas restore /restore 12345678
sudo restic-nas restore-repository
sudo restic-nas verify
sudo restic-nas status
```

The CLI is a thin layer over the existing scripts, so the original commands remain available for compatibility.

## Restore files from a snapshot

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

## Full repository recovery

If the local Restic repository at `/srv/rest-server/data` is lost or needs to be replaced by the NAS mirror, use:

```bash
sudo /usr/local/sbin/restic-nas-restore-repository
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

> The recovery command intentionally does not reinstall Debian, Docker, or other system software. It restores the Restic repository data used by `rest-server`.

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

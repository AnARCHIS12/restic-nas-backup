# restic-nas-backup

Automate a local Restic repository mirror to an SMB/NAS share with systemd.

## What it does

This project mirrors an existing Restic repository, for example:

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

The service stops `rest-server` while the repository is copied, then starts it again when the copy finishes.

The timer runs every day at **13:00** using the server's local timezone. For a Debian server configured with `Europe/Paris`, this means 13:00 Paris time.

## Security

Do not commit:

- Restic repository data
- Restic keys
- repository passwords
- SMB credential files
- private IP addresses or local network configuration

The public repository only contains generic scripts and examples.

## Requirements

- Linux with systemd
- Docker
- `rest-server` running in a Docker container
- `rsync`
- An SMB/CIFS NAS share
- A mounted destination such as `/mnt/restic`

## NAS mount

Mount the NAS share first. Example:

```fstab
//NAS_IP/Restic /mnt/restic cifs credentials=/root/.smb-restic,vers=3.0,sec=ntlmssp,_netdev,nofail,x-systemd.automount 0 0
```

Keep the real NAS IP and SMB credentials on the server, not in this repository.

Check the mount:

```bash
findmnt /mnt/restic
```

It must show the expected CIFS share.

## Installation

Clone the repository:

```bash
git clone https://github.com/AnARCHIS12/restic-nas-backup.git
cd restic-nas-backup
```

Install:

```bash
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
NAS_SOURCE="//192.0.2.10/Restic"
REST_SERVER_CONTAINER="rest-server"
RSYNC_OPTIONS="-aHAX --numeric-ids --delete-delay"
```

Replace the example NAS source with your real local share. Do not commit that value back to the public repository.

## Test

Before testing, make sure the NAS is mounted and the repository is valid.

```bash
findmnt /mnt/restic
sudo systemctl start restic-nas-sync.service
sudo journalctl -u restic-nas-sync.service -n 100 --no-pager
```

Check the timer:

```bash
systemctl list-timers restic-nas-sync.timer
```

The next daily run is scheduled for 13:00.

## Restore

The NAS copy is a Restic repository. To list its snapshots:

```bash
sudo restic -r /mnt/restic snapshots
```

Or use the helper:

```bash
sudo /usr/local/sbin/restic-restore.sh
```

It will show the available snapshots and ask which snapshot to restore. By default it restores to:

```
/restore
```

You can also specify the target and snapshot ID:

```bash
sudo /usr/local/sbin/restic-restore.sh /restore 12345678
```

The Restic repository password is still required for operations on the repository.

## Manual controls

Run a synchronization manually:

```bash
sudo systemctl start restic-nas-sync.service
```

See logs:

```bash
sudo journalctl -u restic-nas-sync.service -f
```

Stop automatic scheduling:

```bash
sudo systemctl disable --now restic-nas-sync.timer
```

Re-enable it:

```bash
sudo systemctl enable --now restic-nas-sync.timer
```

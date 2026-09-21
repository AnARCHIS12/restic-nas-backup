# Testing the Web GUI locally

The web GUI is a separate project built on top of the existing restic-nas CLI.

GUI repository:
https://github.com/AnARCHIS12/restic-nas-backup-gui

For the complete local-only installation procedure, see LOCAL-TESTING.md in the GUI repository.

## Local architecture

~~~text
Browser
  |
  | http://192.168.0.65:18743
  v
Restic NAS Backup GUI
  |
  | Unix socket
  v
Host agent
  |
  v
restic-nas CLI
  |
  +--> Restic repository
  +--> NAS
~~~

The local test does not require Pangolin, a public DNS name, or public HTTPS.

## Quick start

On the backup host:

~~~bash
cd /opt
sudo git clone https://github.com/AnARCHIS12/restic-nas-backup-gui.git
cd /opt/restic-nas-backup-gui
~~~

Verify the CLI:

~~~bash
sudo /usr/local/sbin/restic-nas status
~~~

Then follow LOCAL-TESTING.md.

The first test should use a locally built Docker image:

~~~bash
docker compose build
docker compose up -d
~~~

Open:

~~~text
http://192.168.0.65:18743/
~~~

Do not publish the service through Pangolin until the local tests pass.

## Safety

Start with status, schedule and verify.

Then test backup and a snapshot restoration into a temporary directory.

Do not perform full repository recovery during the first GUI test.

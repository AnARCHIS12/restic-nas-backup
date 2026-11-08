# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-11-09

### Added
- Optional credential support via `RESTIC_PASSWORD_FILE` and `RESTIC_PASSWORD` in `/etc/restic-nas-sync.conf`.
- Unattended non-interactive execution for `restic-nas verify` and automated restore routines.
- Updated documentation and presentation cards detailing full repository recovery and automated checks.

### Changed
- Replaced deprecated Docker `--time` and `-t` stop options with standard `--timeout 30` across all scripts.
- Automatically inherit and export configuration parameters inside `scripts/restic-restore.sh`.

## [0.1.0] - 2026-09-22

### Added
- Initial public release of the `restic-nas-backup` toolkit.
- Automatic synchronization of Restic repository to SMB/CIFS NAS shares with systemd timer.
- Unified `restic-nas` CLI with scheduling, backup, verify, status, snapshot restoration, and repository recovery.

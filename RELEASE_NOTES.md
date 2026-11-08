# Release Notes — restic-nas-backup v0.2.0

## Overview

Version 0.2.0 introduces unattended verification capabilities and modernizes container lifecycle management across the toolkit.

## Highlights

### Modernized Docker Container Lifecycle
- Updated container shutdown procedures to use `--timeout 30`, fully eliminating deprecation warnings emitted by recent Docker engine releases (`Flag --time has been deprecated`).

### Non-Interactive Repository Verification
- Added native support for optional credential declaration (`RESTIC_PASSWORD_FILE` and `RESTIC_PASSWORD`) in `/etc/restic-nas-sync.conf`.
- Enables automated execution of `restic-nas verify` without blocking on interactive standard input.
- Fully backward compatible: if no credential variable is set, standard interactive password prompts are preserved.

### Unified Configuration Inheritance
- `scripts/restic-restore.sh` now sources the central configuration file, ensuring consistent repository path resolution and credential propagation across standalone invocations.

### Presentation & Documentation Update
- Updated project presentation pages with comprehensive coverage of repository recovery, non-interactive checks, and unified CLI operations.

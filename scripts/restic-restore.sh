#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="${REPOSITORY:-/mnt/restic}"
TARGET="${1:-/restore}"
SNAPSHOT_ID="${2:-}"

command -v restic >/dev/null 2>&1 || {
    echo "ERROR: restic is not installed." >&2
    exit 1
}

mountpoint -q "$REPOSITORY" 2>/dev/null || {
    echo "ERROR: $REPOSITORY is not mounted." >&2
    echo "Mount the NAS share containing the Restic repository first." >&2
    exit 1
}

echo "Repository: $REPOSITORY"
echo "Target:     $TARGET"
echo

if [[ -z "$SNAPSHOT_ID" ]]; then
    echo "Available snapshots:"
    restic -r "$REPOSITORY" snapshots
    echo
    read -r -p "Snapshot ID to restore: " SNAPSHOT_ID
fi

[[ -n "$SNAPSHOT_ID" ]] || {
    echo "ERROR: no snapshot ID supplied." >&2
    exit 1
}

mkdir -p "$TARGET"

echo "Restoring snapshot $SNAPSHOT_ID into $TARGET ..."
restic -r "$REPOSITORY" restore "$SNAPSHOT_ID" --target "$TARGET"

echo
echo "Restore completed: $TARGET"

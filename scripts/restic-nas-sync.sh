#!/usr/bin/env bash
set -Eeuo pipefail
CONFIG="${RESTIC_NAS_CONF:-/etc/restic-nas-sync.conf}"
[[ -f "$CONFIG" ]] && source "$CONFIG"

RESTIC_DATA="${RESTIC_DATA:-/srv/rest-server/data}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/restic}"
NAS_IP="${NAS_IP:-}"
NAS_SHARE="${NAS_SHARE:-Restic}"
REST_SERVER_CONTAINER="${REST_SERVER_CONTAINER:-rest-server}"
RSYNC_OPTIONS="${RSYNC_OPTIONS:--aHAX --numeric-ids --delete-delay}"

LOG_TAG="restic-nas-sync"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
    logger -t "$LOG_TAG" -- "$*" 2>/dev/null || true
}

die() {
    log "ERROR: $*"
    exit 1
}

exec 9>/run/lock/restic-nas-sync.lock
flock -n 9 || die "A synchronization is already running."

command -v rsync >/dev/null 2>&1 || die "rsync is not installed."
command -v docker >/dev/null 2>&1 || die "docker is not installed."
command -v findmnt >/dev/null 2>&1 || die "findmnt is not installed."

[[ -d "$RESTIC_DATA" ]] || die "Source repository does not exist: $RESTIC_DATA"
[[ -d "$MOUNT_POINT" ]] || die "Mount point does not exist: $MOUNT_POINT"
[[ -n "$NAS_IP" ]] || die "NAS_IP is not configured."

NAS_SOURCE="//${NAS_IP}/${NAS_SHARE}"

mountpoint -q "$MOUNT_POINT" || die "$MOUNT_POINT is not a mounted filesystem."

actual_source="$(findmnt -no SOURCE --target "$MOUNT_POINT" || true)"
[[ "$actual_source" == "$NAS_SOURCE" ]] || die "Wrong destination: expected $NAS_SOURCE but found $actual_source"

for required in config keys data index snapshots; do
    [[ -e "$RESTIC_DATA/$required" ]] || die "Restic repository looks incomplete: missing $required"
done

probe="$MOUNT_POINT/.restic-nas-sync-write-test"
touch "$probe"
rm -f "$probe"

was_running=false
container_state="$(docker inspect -f '{{.State.Running}}' "$REST_SERVER_CONTAINER" 2>/dev/null || true)"
if [[ "$container_state" == "true" ]]; then
    was_running=true
    log "Stopping $REST_SERVER_CONTAINER..."
    docker stop -t 30 "$REST_SERVER_CONTAINER"
fi

restart_container() {
    if [[ "$was_running" == "true" ]]; then
        log "Restarting $REST_SERVER_CONTAINER..."
        docker start "$REST_SERVER_CONTAINER" >/dev/null
    fi
}
trap restart_container EXIT

log "Synchronizing $RESTIC_DATA -> $MOUNT_POINT"
# shellcheck disable=SC2086
rsync $RSYNC_OPTIONS --info=progress2 "$RESTIC_DATA/" "$MOUNT_POINT/"

log "Synchronization completed successfully."

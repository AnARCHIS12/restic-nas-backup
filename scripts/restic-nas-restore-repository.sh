#!/usr/bin/env bash
set -Eeuo pipefail
CONFIG="${RESTIC_NAS_CONF:-/etc/restic-nas-sync.conf}"
[[ -f "$CONFIG" ]] && source "$CONFIG"

REPOSITORY="${REPOSITORY:-/mnt/restic}"
RESTIC_DATA="${RESTIC_DATA:-/srv/rest-server/data}"
REST_SERVER_CONTAINER="${REST_SERVER_CONTAINER:-rest-server}"
NAS_IP="${NAS_IP:-}"
NAS_SHARE="${NAS_SHARE:-Restic}"
RSYNC_OPTIONS="${RSYNC_OPTIONS:--aHAX --numeric-ids --delete}"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
    logger -t "restic-nas-restore-repository" -- "$*" 2>/dev/null || true
}

die() {
    log "ERROR: $*"
    exit 1
}

command -v rsync >/dev/null 2>&1 || die "rsync is not installed."
command -v docker >/dev/null 2>&1 || die "docker is not installed."
command -v findmnt >/dev/null 2>&1 || die "findmnt is not installed."

[[ -d "$REPOSITORY" ]] || die "NAS repository path does not exist: $REPOSITORY"
[[ -d "$RESTIC_DATA" ]] || die "Local Restic data path does not exist: $RESTIC_DATA"
[[ -n "$NAS_IP" ]] || die "NAS_IP is not configured."

NAS_SOURCE="//${NAS_IP}/${NAS_SHARE}"

mountpoint -q "$REPOSITORY" || die "$REPOSITORY is not a mounted filesystem."
actual_source="$(findmnt -no SOURCE --target "$REPOSITORY" || true)"
[[ "$actual_source" == "$NAS_SOURCE" ]] || die "Wrong destination: expected $NAS_SOURCE but found $actual_source"

for required in config keys data index snapshots; do
    [[ -e "$REPOSITORY/$required" ]] || die "NAS Restic repository looks incomplete: missing $required"
done

echo
echo "============================================================"
echo " Restic repository recovery from NAS"
echo "============================================================"
echo
echo "Source : $REPOSITORY ($NAS_SOURCE)"
echo "Target : $RESTIC_DATA"
echo
echo "WARNING: the local Restic repository will be replaced by"
echo "the NAS copy. Existing local files will be deleted when"
echo "they are not present in the NAS repository."
echo
read -r -p "Type RESTORE to continue: " confirmation
[[ "$confirmation" == "RESTORE" ]] || die "Recovery cancelled."

was_running=false
container_state="$(docker inspect -f '{{.State.Running}}' "$REST_SERVER_CONTAINER" 2>/dev/null || true)"

if [[ "$container_state" == "true" ]]; then
    was_running=true
    log "Stopping $REST_SERVER_CONTAINER..."
    docker stop -t 30 "$REST_SERVER_CONTAINER" >/dev/null
fi

restart_container() {
    if [[ "$was_running" == "true" ]]; then
        log "Restarting $REST_SERVER_CONTAINER..."
        docker start "$REST_SERVER_CONTAINER" >/dev/null
    fi
}
trap restart_container EXIT

log "Restoring NAS repository: $REPOSITORY -> $RESTIC_DATA"
# shellcheck disable=SC2086
rsync $RSYNC_OPTIONS --info=progress2 "$REPOSITORY/" "$RESTIC_DATA/"

log "Repository recovery completed successfully."

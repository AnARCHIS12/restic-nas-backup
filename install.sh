#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

install -d -m 0755 /usr/local/sbin
install -m 0750 "$ROOT_DIR/scripts/restic-nas-sync.sh" /usr/local/sbin/restic-nas-sync.sh
install -m 0750 "$ROOT_DIR/scripts/restic-restore.sh" /usr/local/sbin/restic-restore.sh

install -d -m 0755 /etc/systemd/system
install -m 0644 "$ROOT_DIR/systemd/restic-nas-sync.service" /etc/systemd/system/restic-nas-sync.service
install -m 0644 "$ROOT_DIR/systemd/restic-nas-sync.timer" /etc/systemd/system/restic-nas-sync.timer

if [[ ! -f /etc/restic-nas-sync.conf ]]; then
    install -m 0600 "$ROOT_DIR/config/restic-nas-sync.conf.example" /etc/restic-nas-sync.conf
    echo "Created /etc/restic-nas-sync.conf"
else
    echo "Keeping existing /etc/restic-nas-sync.conf"
fi

systemctl daemon-reload
systemctl enable --now restic-nas-sync.timer

echo
echo "Installed."
echo "Edit /etc/restic-nas-sync.conf and set NAS_SOURCE."
echo
systemctl status --no-pager restic-nas-sync.timer
echo
echo "Test manually with:"
echo "  systemctl start restic-nas-sync.service"

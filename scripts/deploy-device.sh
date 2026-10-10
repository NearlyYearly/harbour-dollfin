#!/usr/bin/env bash
# Copy the newest built RPM to a Sailfish device and install it.
#
#   scripts/deploy-device.sh [user@host]
#
# Default host is defaultuser@192.168.2.15, the fixed address of the phone's USB
# developer-mode network. For WLAN, pass e.g. defaultuser@192.168.x.y
#
# Prerequisites on the phone (Settings > Developer tools):
#   - Developer mode ON
#   - Remote connection ON
#   - an SSH password set (this is also the devel-su password)
set -euo pipefail

target="${1:-defaultuser@192.168.2.15}"
repo_root=$(cd "$(dirname "$0")/.." && pwd)

rpm=$(ls -t "$repo_root"/RPMS/harbour-dollfin-*.aarch64.rpm 2>/dev/null | head -1 || true)
if [ -z "$rpm" ]; then
    echo "No RPM in RPMS/ — run scripts/build-rpm.sh first." >&2
    exit 1
fi
name=$(basename "$rpm")

echo "==> Copying $name to $target"
scp "$rpm" "$target:~/"

echo "==> Installing (devel-su asks for your developer-mode SSH password)"
ssh -t "$target" "devel-su rpm -Uvh --force ~/$name"

echo "==> Done. Launch 'Dollfin' from the app grid."

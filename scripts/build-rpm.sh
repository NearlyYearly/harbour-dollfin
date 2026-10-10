#!/usr/bin/env bash
# Build a Sailfish OS RPM for dollfin without the full Sailfish SDK, using the
# community Platform SDK container image via podman.
#
#   scripts/build-rpm.sh [release] [arch]
#     release  default 5.2.0.15
#     arch     default aarch64
#
# Tags: https://hub.docker.com/r/coderus/sailfishos-platform-sdk/tags
# Output: RPMS/harbour-dollfin-<version>-1.<arch>.rpm
#
# The user juggling below is needed because:
#   - the image's build user (mersdk, uid 100000) is outside our rootless
#     subuid range, so rootless podman cannot run as it;
#   - mb2 refuses to run as root;
# so we start as container root, move mersdk into the subuid range, and drop to
# it with `chroot --userspec` (no PAM, unlike su/runuser).
set -euo pipefail

RELEASE="${1:-5.2.0.15}"
ARCH="${2:-aarch64}"
IMAGE="docker.io/coderus/sailfishos-platform-sdk:${RELEASE}"
TARGET="SailfishOS-${RELEASE}-${ARCH}"

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

echo "==> Building ${TARGET} with ${IMAGE}"
podman run --rm --user 0:0 -v "${repo_root}:/workspace:Z" --entrypoint bash "${IMAGE}" -lc "
set -e
groupmod -g 1000 mersdk
usermod -u 1000 -g 1000 mersdk
chown -R mersdk:mersdk /home/mersdk /srv/mer
rm -rf /home/mersdk/build && mkdir -p /home/mersdk/build
cp -a /workspace/. /home/mersdk/build/
cd /home/mersdk/build && rm -rf .git RPMS
chown -R mersdk:mersdk /home/mersdk/build
chroot --userspec=1000:1000 / /bin/bash -lc 'export HOME=/home/mersdk; cd /home/mersdk/build && mb2 -t ${TARGET} build'
mkdir -p /workspace/RPMS
cp /home/mersdk/build/RPMS/*.rpm /workspace/RPMS/
"

echo "==> Done"
ls -l "${repo_root}/RPMS"

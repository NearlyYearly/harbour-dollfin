#!/usr/bin/env bash
# Build and run the unit tests inside the Sailfish Platform SDK container.
# QtTest is not packaged in the target, so tests use a tiny in-tree harness.
#   scripts/run-tests.sh [release] [arch]
set -euo pipefail

RELEASE="${1:-5.2.0.15}"
ARCH="${2:-aarch64}"
IMAGE="docker.io/coderus/sailfishos-platform-sdk:${RELEASE}"
TARGET="SailfishOS-${RELEASE}-${ARCH}"

repo_root=$(cd "$(dirname "$0")/.." && pwd)

echo "==> Running tests for ${TARGET}"
podman run --rm --user 0:0 -v "${repo_root}:/workspace:Z" --entrypoint bash "${IMAGE}" -lc "
set -e
groupmod -g 1000 mersdk
usermod -u 1000 -g 1000 mersdk
chown -R mersdk:mersdk /home/mersdk /srv/mer
rm -rf /home/mersdk/t && mkdir -p /home/mersdk/t
cp -a /workspace/. /home/mersdk/t/
cd /home/mersdk/t && rm -rf .git RPMS
chown -R mersdk:mersdk /home/mersdk/t
chroot --userspec=1000:1000 / /bin/bash -lc 'export HOME=/home/mersdk; cd /home/mersdk/t && mb2 -t ${TARGET} -s rpm/harbour-dollfin.spec build-init >/dev/null 2>&1; mb2 -t ${TARGET} -s rpm/harbour-dollfin.spec build-shell ./tests/run.sh'
"

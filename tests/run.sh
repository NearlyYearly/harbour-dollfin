#!/bin/sh
# Runs inside a Sailfish SDK build shell (invoked by scripts/run-tests.sh).
# Builds and runs the unit tests for the target architecture.
set -e
cd "$(dirname "$0")/tst_core"
qmake
make -j"$(nproc 2>/dev/null || echo 1)"
./tst_core

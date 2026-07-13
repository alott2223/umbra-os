#!/bin/bash
# Build the Umbra OS ISO inside a Debian container.
# Works from Windows (Docker Desktop / WSL2 backend), macOS, or Linux.
#
# The build runs in the container's own filesystem (live-build's chroot,
# mknod and hardlink operations fail on NTFS/9p-mounted volumes); only the
# finished ISO is copied back to ./out on the host.
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p out

docker run --rm --privileged \
    -v "$PWD":/src \
    debian:trixie \
    bash /src/container-build.sh

echo "ISO written to ./out/"

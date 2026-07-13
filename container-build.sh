#!/bin/bash
# Runs INSIDE the build container (see build-in-docker.sh). Expects the repo
# mounted at /src; builds in /build (container FS) and copies the ISO to /src/out.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends live-build ca-certificates

mkdir -p /build
cp -a /src/. /build/
rm -rf /build/work /build/out
cd /build

# Defensive: normalize line endings and exec bits lost on Windows checkouts
find /build -type f \( -name "*.sh" -o -name "*.hook.chroot" -o -name "*.conf" \
    -o -name "*.cfg" -o -name "*.rules" -o -name "*.chroot" -o -name "*.script" \
    -o -name "*.nft" -o -name "*.plymouth" \) -exec sed -i 's/\r$//' {} +
chmod +x /build/build.sh /build/config/hooks/normal/*.hook.chroot \
    /build/config/includes.chroot/usr/local/sbin/*

/build/build.sh

mkdir -p /src/out
cp /build/out/*.iso /src/out/
( cd /build/out && sha256sum ./*.iso ) > /src/out/SHA256SUMS
echo "container-build: done"

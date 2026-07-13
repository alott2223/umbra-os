#!/bin/bash
# Umbra OS — build & install GrapheneOS hardened_malloc, then enable it system-wide.
# Opt-in (not baked into the ISO, so the image build stays offline-deterministic).
#
#   sudo umbra-hardened-malloc.sh          build + install + preload (light config)
#   sudo umbra-hardened-malloc.sh --disable  remove from /etc/ld.so.preload
#
# hardened_malloc is a security-focused allocator (GrapheneOS): guard slabs,
# randomized allocation, canaries, zero-on-free. It can break a few apps; if
# something misbehaves, run with --disable and file which app.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }

LIB=/usr/lib/libhardened_malloc.so
PRELOAD=/etc/ld.so.preload

if [[ "${1:-}" == "--disable" ]]; then
    [[ -f "$PRELOAD" ]] && sed -i "\#$LIB#d" "$PRELOAD"
    echo "hardened_malloc removed from preload. Reboot to fully revert."
    exit 0
fi

echo "==> installing build deps"
apt-get update
apt-get install -y --no-install-recommends build-essential git gcc make

echo "==> building hardened_malloc"
TMP=$(mktemp -d)
git clone --depth 1 https://github.com/GrapheneOS/hardened_malloc "$TMP/hm"
make -C "$TMP/hm" VARIANT=light
install -m 0644 "$TMP/hm/out-light/libhardened_malloc-light.so" "$LIB"
rm -rf "$TMP"

echo "==> enabling via $PRELOAD"
touch "$PRELOAD"
grep -qxF "$LIB" "$PRELOAD" || echo "$LIB" >> "$PRELOAD"

echo "Done. hardened_malloc (light variant) is now preloaded system-wide."
echo "If any app misbehaves: sudo umbra-hardened-malloc.sh --disable"

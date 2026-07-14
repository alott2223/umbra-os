#!/bin/bash
# Umbra OS — boot oneshot: enforce AppArmor, and a DNS safety net.
# DNS is handled by NetworkManager (dns=default) which writes /etc/resolv.conf
# directly, so this only steps in if resolv.conf is somehow empty/broken.
set -uo pipefail

systemctl restart apparmor.service 2>/dev/null || true

# DNS safety net: if, after NM has had a moment, nothing resolves AND resolv.conf
# has no usable server, drop in a public resolver so the box is never DNS-dead.
for _ in 1 2 3 4 5; do
    getent hosts deb.debian.org >/dev/null 2>&1 && exit 0
    sleep 2
done
if ! grep -qE '^nameserver +[0-9]' /etc/resolv.conf 2>/dev/null; then
    printf 'nameserver 9.9.9.9\nnameserver 1.1.1.1\n' > /etc/resolv.conf 2>/dev/null || true
fi
exit 0

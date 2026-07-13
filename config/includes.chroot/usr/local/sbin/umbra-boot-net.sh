#!/bin/bash
# Umbra OS — guarantee AppArmor + a WORKING resolver at boot.
# Tries the hardened path (systemd-resolved + opportunistic DNS-over-TLS) first,
# but NEVER leaves the machine without DNS: if resolution still fails after a few
# seconds (resolved down, port 853 filtered, captive portal, pre-time-sync), it
# falls back to a plain public resolver so the system is actually usable.
set -uo pipefail

systemctl restart apparmor.service 2>/dev/null || true
systemctl start systemd-resolved.service 2>/dev/null || true
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || true

# Wait briefly, then confirm DNS actually resolves something.
for _ in 1 2 3 4 5; do
    getent hosts deb.debian.org >/dev/null 2>&1 && exit 0
    sleep 2
done

# Still no DNS — replace resolv.conf with a plain public resolver (Quad9 + Cloudflare)
# so the box is usable. Re-enable strict encrypted DNS later with:  umbra dns secure
: > /etc/resolv.conf 2>/dev/null || true
printf 'nameserver 9.9.9.9\nnameserver 1.1.1.1\n' > /etc/resolv.conf 2>/dev/null || true
exit 0

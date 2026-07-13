#!/bin/bash
# Umbra OS — emergency "panic" wipe. Destroys volatile secrets and powers off
# HARD so an attacker who seizes the machine gets a locked, keyless system.
#
# What it does (fast, best-effort, in this order):
#   1. Drop all network (kill-switch to full deny) so nothing exfiltrates mid-wipe.
#   2. LuksSuspend / wipe the LUKS master key from kernel memory for mounted
#      encrypted volumes, so RAM no longer holds the disk key.
#   3. Flush swap and drop caches.
#   4. Force immediate poweroff (RAM contents decay; disk stays encrypted at rest).
#
# This protects a *powered-off, encrypted-at-rest* machine. It does NOT shred the
# disk. Your data survives (it's still LUKS-encrypted) — what's destroyed is the
# in-memory key, which is the thing an attacker with physical access races for.
#
#   sudo umbra-panic            # for real: cut net, evict keys, hard poweroff
#   sudo umbra-panic --dry-run  # rehearse: show exactly what would happen, do nothing
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }

DRY=0
[[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]] && DRY=1

if [[ $DRY -eq 1 ]]; then
    echo "== UMBRA PANIC (DRY RUN) — nothing will actually happen =="
    echo "Would drop ALL network (nft flush + deny-all output chain)."
    echo "Would luksSuspend these active encrypted volumes (evicting keys from RAM):"
    mapfile -t _dm < <(dmsetup ls --target crypt 2>/dev/null | awk '{print $1}')
    if [[ ${#_dm[@]} -eq 0 ]]; then
        echo "    (none found — e.g. on the live ISO; on an installed encrypted"
        echo "     system your root volume would be listed and locked here)"
    else
        printf '    %s\n' "${_dm[@]}"
    fi
    echo "Would swapoff -a, sync, drop caches, then HARD poweroff (sysrq 'o')."
    echo "== end dry run. Run without --dry-run to actually trigger. =="
    exit 0
fi

echo "!! UMBRA PANIC: cutting network, evicting disk keys, powering off"

# 1. full network deny
nft flush ruleset 2>/dev/null || true
nft 'add table inet panic; add chain inet panic o { type filter hook output priority 0; policy drop; }' 2>/dev/null || true

# 2. evict LUKS master keys from RAM for every active mapping
for dm in $(dmsetup ls --target crypt 2>/dev/null | awk '{print $1}'); do
    cryptsetup luksSuspend "$dm" 2>/dev/null || true
done

# 3. swap + caches
swapoff -a 2>/dev/null || true
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

# 4. hard power off (bypass clean shutdown so nothing gets re-flushed to disk)
echo o > /proc/sysrq-trigger 2>/dev/null || systemctl poweroff -f

#!/bin/bash
# Umbra OS ISO build. Run as root on Debian/Ubuntu (native or WSL2).
# Produces: out/umbra-os-amd64.hybrid.iso
set -euo pipefail

cd "$(dirname "$0")"

if [[ $EUID -ne 0 ]]; then
    echo "error: live-build needs root. Re-run with sudo." >&2
    exit 1
fi
if ! command -v lb >/dev/null 2>&1; then
    echo "error: live-build not installed. Run: apt install live-build" >&2
    exit 1
fi

DIST="${UMBRA_DIST:-trixie}"
WORK=work
mkdir -p "$WORK" out
cp -a config "$WORK/"
cd "$WORK"

lb config \
    --distribution "$DIST" \
    --architectures amd64 \
    --archive-areas "main contrib non-free-firmware" \
    --debian-installer live \
    --debian-installer-gui true \
    --binary-images iso-hybrid \
    --compression xz \
    --apt-indices false \
    --bootappend-live "boot=live components quiet splash slab_nomerge init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 randomize_kstack_offset=on pti=on vsyscall=none debugfs=off oops=panic lockdown=confidentiality mce=0 iommu.strict=1 iommu.passthrough=0 efi=disable_early_pci_dma random.trust_cpu=off random.trust_bootloader=off mitigations=auto,nosmt apparmor=1" \
    --security true \
    --updates true \
    --apt-secure true \
    --iso-application "Umbra OS" \
    --iso-publisher "Umbra OS Project" \
    --iso-volume "UMBRA"

lb build

mv -f live-image-amd64.hybrid.iso ../out/umbra-os-amd64.hybrid.iso
echo
echo "Done: out/umbra-os-amd64.hybrid.iso"
echo "After install, run: umbra-harden-install.sh  then  umbra-verify.sh"

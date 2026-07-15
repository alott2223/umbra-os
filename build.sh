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
EDITION="${UMBRA_EDITION:-base}"        # base | redteam
WORK=work
mkdir -p "$WORK" out
cp -a config "$WORK/"
cd "$WORK"

# Edition selection: enable the redteam package list + hook, and name the image.
ISO_APP="Umbra OS"; ISO_VOL="UMBRA"; ISO_NAME="umbra-os-amd64.hybrid.iso"
if [ "$EDITION" = "redteam" ]; then
    echo "==> building the RED TEAM edition"
    for f in config/package-lists/redteam.list.chroot.disabled \
             config/hooks/normal/0400-umbra-redteam.hook.chroot.disabled; do
        [ -f "$f" ] && mv -f "$f" "${f%.disabled}"
    done
    chmod +x config/hooks/normal/0400-umbra-redteam.hook.chroot 2>/dev/null || true
    ISO_APP="Umbra OS Red Team"; ISO_VOL="UMBRA-RT"; ISO_NAME="umbra-os-redteam-amd64.hybrid.iso"
fi

lb config \
    --distribution "$DIST" \
    --architectures amd64 \
    --archive-areas "main contrib non-free-firmware" \
    --debian-installer live \
    --debian-installer-gui true \
    --binary-images iso-hybrid \
    --compression xz \
    --apt-indices false \
    --bootappend-live "boot=live components live-config.user-fullname=Umbra live-config.hostname=umbra quiet splash slab_nomerge init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 randomize_kstack_offset=on pti=on vsyscall=none debugfs=off oops=panic lockdown=confidentiality mce=0 iommu.strict=1 iommu.passthrough=0 efi=disable_early_pci_dma random.trust_cpu=off random.trust_bootloader=off mitigations=auto,nosmt apparmor=1" \
    --security true \
    --updates true \
    --apt-secure true \
    --iso-application "$ISO_APP" \
    --iso-publisher "Umbra OS Project" \
    --iso-volume "$ISO_VOL"

lb build

mv -f live-image-amd64.hybrid.iso "../out/$ISO_NAME"
echo
echo "Done: out/$ISO_NAME"
echo "After install, run: umbra-harden-install.sh  then  umbra-verify.sh"

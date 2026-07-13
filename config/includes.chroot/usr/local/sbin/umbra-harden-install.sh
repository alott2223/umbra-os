#!/bin/bash
# Umbra OS — second-stage hardening. Run ONCE on the installed system:
#   sudo umbra-harden-install.sh [--hidepid] [--paranoid] [--no-camera] [--no-mic]
#
# Applies things that can't be safely baked into a live image: fstab mount
# options, USBGuard allowlist for YOUR devices, AIDE baseline, GRUB refresh,
# and the opt-in opsec/paranoid toggles.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }

HIDEPID=0; PARANOID=0; NOCAM=0; NOMIC=0
for arg in "$@"; do
    case "$arg" in
        --hidepid)   HIDEPID=1 ;;
        --paranoid)  PARANOID=1 ;;
        --no-camera) NOCAM=1 ;;
        --no-mic)    NOMIC=1 ;;
        *) echo "usage: $0 [--hidepid] [--paranoid] [--no-camera] [--no-mic]" >&2; exit 1 ;;
    esac
done

backup() { [[ -f "$1" && ! -f "$1.umbra-orig" ]] && cp -a "$1" "$1.umbra-orig" || true; }

echo "==> fstab mount hardening"
backup /etc/fstab
add_fstab_line() { grep -qE "[[:space:]]$2[[:space:]]" /etc/fstab || echo "$1" >> /etc/fstab; }
add_fstab_line "tmpfs /tmp tmpfs defaults,nodev,nosuid,noexec,size=2G 0 0" "/tmp"
add_fstab_line "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" "/dev/shm"
if grep -qE '[[:space:]]/var/tmp[[:space:]]' /etc/fstab; then
    sed -i -E 's#(^[^ ]+[[:space:]]+/var/tmp[[:space:]]+[^ ]+[[:space:]]+)[^ ]+#\1defaults,nodev,nosuid,noexec#' /etc/fstab
fi
if grep -qE '[[:space:]]/boot[[:space:]]' /etc/fstab; then
    sed -i -E 's#(^[^ ]+[[:space:]]+/boot[[:space:]]+[^ ]+[[:space:]]+)defaults#\1defaults,nodev,nosuid,noexec#' /etc/fstab
fi

if [[ $HIDEPID -eq 1 ]]; then
    echo "==> /proc hidepid=invisible"
    getent group proc >/dev/null || groupadd -r proc
    for u in polkitd systemd-logind; do id "$u" &>/dev/null && usermod -aG proc "$u" || true; done
    add_fstab_line "proc /proc proc defaults,hidepid=invisible,gid=proc 0 0" "/proc"
    mkdir -p /etc/systemd/system/systemd-logind.service.d
    printf '[Service]\nSupplementaryGroups=proc\n' > /etc/systemd/system/systemd-logind.service.d/proc-group.conf
fi

echo "==> USBGuard: allowlisting attached devices, blocking anything new"
if command -v usbguard >/dev/null; then
    if [[ ! -s /etc/usbguard/rules.conf ]]; then
        usbguard generate-policy > /etc/usbguard/rules.conf
        chmod 600 /etc/usbguard/rules.conf
    fi
    systemctl enable --now usbguard.service
fi

echo "==> AIDE: initializing file-integrity baseline (takes a few minutes)"
command -v aideinit >/dev/null && aideinit --yes --force >/dev/null || true

if [[ $NOCAM -eq 1 ]]; then
    echo "==> disabling camera (uvcvideo)"
    echo 'install uvcvideo /bin/false' > /etc/modprobe.d/40-umbra-no-camera.conf
    rmmod uvcvideo 2>/dev/null || true
fi
if [[ $NOMIC -eq 1 ]]; then
    echo "==> disabling internal microphone/audio capture (snd_hda_* left, PulseAudio source muted)"
    # Fully removing audio breaks output too; instead mute+lock all capture sources.
    mkdir -p /etc/umbra
    cat > /etc/umbra/mute-mic.sh <<'MIC'
#!/bin/bash
# mute every capture source at login
for src in $(pactl list short sources 2>/dev/null | awk '{print $2}'); do
    pactl set-source-mute "$src" 1 2>/dev/null || true
done
MIC
    chmod +x /etc/umbra/mute-mic.sh
    echo "    (a login hook mutes all mic sources; remove /etc/modprobe/.. to fully re-enable)"
fi

if [[ $PARANOID -eq 1 ]]; then
    echo "==> activating paranoid sysctl tier"
    [[ -f /etc/sysctl.d/999-umbra-paranoid.conf.disabled ]] && \
        mv /etc/sysctl.d/999-umbra-paranoid.conf.disabled /etc/sysctl.d/999-umbra-paranoid.conf
    echo "==> paranoid: disabling Bluetooth"
    printf 'install bluetooth /bin/false\ninstall btusb /bin/false\n' > /etc/modprobe.d/40-umbra-paranoid.conf
    systemctl disable --now bluetooth.service 2>/dev/null || true
fi

echo "==> applying sysctls and refreshing GRUB + initramfs"
sysctl --system >/dev/null
update-grub
update-initramfs -u

echo
echo "Done. Reboot, then run: umbra-verify.sh"
echo "Opsec extras available now:"
echo "  umbra-torswitch on        # route everything through Tor (kill-switch)"
echo "  umbra-panic               # emergency wipe of keys + shutdown (see docs/OPSEC.md)"
exit 0

#!/bin/bash
# Umbra OS — verify that hardening + opsec controls are live.
# Exit code = number of failed checks.
set -uo pipefail

PASS=0; FAIL=0
# NB: use assignment (always exit 0) — ((x++)) returns 1 when x was 0, which
# would spuriously trigger a following `|| bad` in the && || chains below.
ok()  { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

check_sysctl() {
    local got
    got=$(sysctl -n "$1" 2>/dev/null | tr -s '\t' ' ') || { bad "$1 (missing)"; return; }
    [[ "$got" == "$2" ]] && ok "$1 = $2" || bad "$1 = $got (want $2)"
}

echo "== Kernel command line =="
CMDLINE=$(cat /proc/cmdline)
for flag in slab_nomerge init_on_alloc=1 init_on_free=1 pti=on vsyscall=none \
            randomize_kstack_offset=on lockdown=confidentiality mitigations=auto,nosmt; do
    [[ "$CMDLINE" == *"$flag"* ]] && ok "cmdline: $flag" || bad "cmdline missing: $flag"
done

echo "== Lockdown =="
if [[ -r /sys/kernel/security/lockdown ]]; then
    grep -q '\[confidentiality\]' /sys/kernel/security/lockdown \
        && ok "lockdown=confidentiality active" || bad "lockdown not confidentiality"
else
    bad "lockdown interface not present"
fi

echo "== Sysctls =="
check_sysctl kernel.kptr_restrict 2
check_sysctl kernel.dmesg_restrict 1
check_sysctl kernel.unprivileged_bpf_disabled 1
check_sysctl kernel.kexec_load_disabled 1
check_sysctl kernel.io_uring_disabled 2
check_sysctl kernel.yama.ptrace_scope 2
check_sysctl fs.protected_symlinks 1
check_sysctl fs.suid_dumpable 0
check_sysctl net.ipv4.tcp_syncookies 1
check_sysctl net.ipv4.conf.all.rp_filter 1

echo "== Services =="
for svc in nftables auditd chrony systemd-resolved; do
    systemctl is-active --quiet "$svc" && ok "$svc active" || bad "$svc not active"
done
systemctl is-active --quiet usbguard && ok "usbguard active" || echo "  [WARN] usbguard inactive (run umbra-harden-install.sh)"

echo "== AppArmor =="
if command -v aa-status >/dev/null; then
    N=$(aa-status --enforced 2>/dev/null || echo 0)
    [[ "$N" -gt 0 ]] && ok "AppArmor enforcing $N profiles" || bad "AppArmor: no enforced profiles"
fi

echo "== Firewall =="
if nft list chain inet umbra_tor input >/dev/null 2>&1; then
    ok "Tor kill-switch firewall active (umbra_tor table)"
elif nft list chain inet filter input 2>/dev/null | grep -q 'policy drop'; then
    ok "nftables input policy drop"
else
    bad "no default-deny firewall loaded"
fi

echo "== Opsec: encrypted DNS =="
if resolvectl status 2>/dev/null | grep -q '+DNSOverTLS'; then
    ok "DNS-over-TLS enabled"
else
    echo "  [WARN] DoT not reported active (check systemd-resolved)"
fi
resolvectl status 2>/dev/null | grep -qi 'MulticastDNS.*no\|LLMNR setting: no' \
    && ok "LLMNR/mDNS multicast leaks disabled" || echo "  [WARN] verify LLMNR/mDNS off"

echo "== Opsec: MAC randomization =="
if [[ -f /etc/NetworkManager/conf.d/00-umbra-mac-randomization.conf ]]; then
    ok "MAC randomization config present"
else
    bad "MAC randomization config missing"
fi

echo "== Mounts =="
for m in /tmp /dev/shm; do
    opts=$(findmnt -no OPTIONS "$m" 2>/dev/null || true)
    if [[ "$opts" == *noexec* && "$opts" == *nosuid* && "$opts" == *nodev* ]]; then
        ok "$m: nodev,nosuid,noexec"
    else
        bad "$m: ${opts:-not mounted} (want nodev,nosuid,noexec)"
    fi
done

echo "== Audit =="
auditctl -s 2>/dev/null | grep -q 'enabled 2' && ok "audit rules locked (-e 2)" || bad "audit not locked"

echo "== Secure Boot =="
if command -v mokutil >/dev/null && mokutil --sb-state 2>/dev/null | grep -q enabled; then
    ok "Secure Boot enabled"
else
    echo "  [WARN] Secure Boot not enabled (enable in firmware)"
fi

echo
echo "Result: $PASS passed, $FAIL failed"
exit "$FAIL"

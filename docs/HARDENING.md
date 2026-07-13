# Umbra OS — hardening control rationale and breakage notes

Security is trade-offs. This explains **why** each control exists, **what** it protects against, and
**what it breaks**. See [OPSEC.md](OPSEC.md) for the privacy/anonymity layer.

## 1. Base distribution

**Debian trixie** — signed packages, a fast-turnaround security team, AppArmor by default, no
telemetry, boring well-audited versions. The whole config ports almost 1:1 to Fedora if you prefer
SELinux + fresher kernels.

## 2. Kernel command line (`/etc/default/grub.d/40-umbra-hardening.cfg`)

| Flag | Protects against | Cost |
|---|---|---|
| `slab_nomerge` | cross-cache slab exploitation | negligible |
| `init_on_alloc=1 init_on_free=1` | uninitialized-memory leaks, some UAF | ~1% perf |
| `page_alloc.shuffle=1` | allocator layout predictability | negligible |
| `randomize_kstack_offset=on` | deterministic kernel-stack attacks | negligible |
| `pti=on` | Meltdown-class leaks (forced) | small perf |
| `vsyscall=none` | legacy fixed-address ROP target | pre-2013 binaries only |
| `debugfs=off` | large debug attack surface | some dev tools lose data |
| `oops=panic` | surviving an exploitable oops to retry | a driver oops reboots |
| `module.sig_enforce=1` | unsigned module rootkits | **breaks DKMS: NVIDIA, VirtualBox, ZFS** |
| `lockdown=confidentiality` | root→kernel escalation, kernel memory reads | breaks hibernation, some bpf/perf |
| `mce=0` | exploitation via tolerated machine-checks | reboots on some HW errors |
| `kvm.nx_huge_pages=force` | iTLB-multihit in KVM | small VM perf |
| `iommu.strict=1 iommu.passthrough=0 efi=disable_early_pci_dma` | DMA attacks (Thunderbolt/PCIe RAM reads) | minor I/O perf |
| `random.trust_cpu=off random.trust_bootloader=off` | trusting opaque entropy sources | slightly slower early entropy |
| `mitigations=auto,nosmt` | all known CPU side channels incl. cross-SMT | **disables HT when unsafe → up to ~30% less parallel throughput** |

Need NVIDIA/DKMS? Drop `module.sig_enforce=1` + `lockdown=confidentiality`, or enroll a MOK and sign.

## 3. Sysctls (`/etc/sysctl.d/990-umbra-hardening.conf`)

Highlights (full list commented in the file):

- **`kernel.io_uring_disabled=2`** — io_uring drove a large share of recent LPEs; Google disabled it
  fleet-wide.
- **`kernel.unprivileged_bpf_disabled=1` + `bpf_jit_harden=2`** — unprivileged eBPF is a recurring
  LPE source and Spectre gadget factory.
- **`kernel.yama.ptrace_scope=2`** — only root may ptrace; stops credential theft from a compromised
  same-user process. Cost: `gdb -p`/`strace -p` need sudo.
- **`kernel.kexec_load_disabled=1`** — blocks live-replacing the kernel (a signed-boot bypass).
- **`fs.protected_*`** — kills the classic /tmp symlink/FIFO/hardlink race exploit class.
- **`core_pattern=|/bin/false` + suid_dumpable=0 + coredump Storage=none** — core dumps leak keys;
  disabled in all three places.
- **Network set** — syncookies, RFC 1337, strict rp_filter, no redirects/source routing, log
  martians, IPv6 RAs off + privacy addresses.

### Baseline keeps user namespaces ON
Disabling unprivileged userns removes attack surface but breaks Chromium/Electron/Flatpak sandboxes
and rootless containers (arguably making a desktop *less* safe). Baseline keeps them on; **paranoid
tier** turns them off for appliance/server use.

## 4. Module blacklist
Uncommon protocols (DCCP/SCTP/RDS/TIPC…), rare filesystems (fuzzing targets triggerable by a USB
stick), and FireWire (DMA-by-design) are `install <mod> /bin/false`. Camera (`uvcvideo`) and mic can
be killed with `umbra-harden-install.sh --no-camera --no-mic`.

## 5. Memory allocator — hardened_malloc (opt-in)
`umbra-hardened-malloc.sh` builds GrapheneOS hardened_malloc and preloads it system-wide (guard
slabs, randomized allocation, canaries, zero-on-free). Not baked into the ISO so the image build
stays offline/deterministic; run it post-install. `--disable` reverts.

## 6. Firewall
`nftables` default-deny inbound, stateful, spoofed-loopback drops, minimal ICMPv6. Egress template
provided. The Tor kill-switch swaps in a separate ruleset (see OPSEC.md).

## 7. AppArmor
Enforcing by default in Debian; `apparmor-profiles-extra` adds more. Enforce additional profiles
deliberately with `aa-enforce` — enforcing everything blindly breaks apps.

## 8. Authentication & sessions
- `pam_faillock`: 5 failures → 10-min lockout.
- `pam_pwhistory`: blocks reuse of the last 5 passwords.
- `pwquality`: 14-char minimum, dictionary check (length beats composition, NIST 800-63B).
- `umask 027`, `HOME_MODE 0700`, `libpam-tmpdir` (per-user $TMPDIR), `su` restricted to sudo group.

## 9. systemd
`system.conf.d/10-umbra.conf` sets `DefaultLimitCORE=0` (belt-and-suspenders no-coredumps) and a
tight default stop timeout.

## 10. Storage
- Installer: choose **encrypted LVM** (LUKS2/argon2id).
- `umbra-harden-install.sh` adds `nodev,nosuid,noexec` to `/tmp`, `/dev/shm`, `/var/tmp`, `/boot`.
- `--hidepid`: processes invisible cross-user in /proc (with a `proc`-group exception for logind).

## 11. Devices
- **USBGuard**: post-install, currently-attached devices become the allowlist; new devices blocked
  until `usbguard allow-device` (defeats BadUSB). Never enabled before a policy exists (would kill
  the keyboard).
- **Thunderbolt**: IOMMU-confined + `bolt`-gated rather than blacklisted.

## 12. Detection & integrity
- **auditd** with a curated ruleset, locked `-e 2` (an attacker with root can't silently disable it
  until reboot).
- **AIDE** baseline at install; check from cron or a trusted USB boot.
- **Lynis + debsums** for on-demand audit (target hardening index ≥ 85).
- **unattended-upgrades** applies security patches daily; **needrestart** flags stale libs.

## 13. Time
- **chrony + NTS** (`authselectmode require`): authenticated time sync so a network attacker can't
  rewind the clock to resurrect expired/revoked certs.

## 14. Optional extras (documented, not automated)
- **GRUB password**: `grub-mkpasswd-pbkdf2` → add a superuser in `/etc/grub.d/40_custom` with
  `--unrestricted` on the default entry.
- **TPM2-bound LUKS** (`systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7`): convenience + evil-maid
  detection, weaker than passphrase-only vs. a stolen powered-off machine. Per threat model.

## Tiers at a glance

| | Baseline ISO | + harden-install | + --paranoid | + torswitch on |
|---|---|---|---|---|
| Kernel/sysctl/cmdline | ✅ | ✅ | + userns/ptrace off, TCP trims | ✅ |
| Passive opsec (MAC/DoT/no-telemetry) | ✅ | ✅ | ✅ | ✅ |
| Mounts, USBGuard, AIDE | — | ✅ | ✅ | ✅ |
| Bluetooth | on | on | off | on |
| All traffic via Tor (fail-closed) | — | — | — | ✅ |
| Daily-driver friendly | yes | yes | servers/appliances | mostly |

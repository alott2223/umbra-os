# Umbra OS

> *stay in the shadow*

A hardened, privacy-first Linux distribution built on **Debian (trixie)** with `live-build`.
Umbra combines a maximal system-hardening baseline (KSPP kernel flags, AppArmor, auditd, USBGuard,
LUKS2, signed modules) with an **opsec layer**: MAC-address randomization, encrypted DNS, metadata
scrubbing, browser hardening, and an opt-in **Tor kill-switch** that routes all traffic through Tor
and fails closed on leaks.

It is the security-hardened successor to the `bastion-linux` base in this repo, rebranded and
extended. Same honest framing as before: for a targeted-attacker threat model the strongest
*architecture* is Qubes OS (hardware compartmentalization) or, for anonymity specifically,
Tails/Whonix. Umbra takes the aggressively-hardened monolithic path — a practical daily driver that
gives up far less usability.

## Layers

| Layer | Controls |
|---|---|
| Boot | KSPP kernel cmdline, `lockdown=confidentiality`, signed-module enforcement, UEFI Secure Boot, Plymouth splash |
| Kernel | ~45 sysctls, io_uring off, unprivileged BPF/userfaultfd off, ptrace restricted, kexec off, module blacklist |
| Memory | init_on_alloc/free, slab_nomerge, kstack randomization, full ASLR, **hardened_malloc** (opt-in build) |
| MAC | AppArmor enforced + extra profiles |
| Auth | faillock lockout, pwquality (14-char), **pwhistory**, umask 027, no core dumps |
| Firewall | nftables default-deny inbound; egress kill-switch template |
| Storage | LUKS2/argon2id FDE (installer), nodev/nosuid/noexec mounts, optional hidepid |
| Devices | USBGuard allowlist, Thunderbolt IOMMU-gated, opt-in camera/mic kill |
| Detection | auditd (locked ruleset), AIDE, Lynis, unattended security upgrades |
| **Opsec** | **MAC randomization, generic hostname, RFC-7844 DHCP anonymity, DoT DNS (Quad9), no LLMNR/mDNS, IPv6 privacy addrs, MAT2 metadata scrubbing, hardened Firefox, UTC clock** |
| **Anonymity** | **opt-in Tor transparent-proxy kill-switch (`umbra-torswitch`), panic wipe (`umbra-panic`)** |

## Tiers

- **Baseline** (in the ISO) — all hardening + passive opsec (MAC randomization, DoT, no telemetry).
  Usable daily driver.
- **Post-install** (`umbra-harden-install.sh`) — mount hardening, USBGuard, AIDE, optional
  `--hidepid`, `--no-camera`, `--no-mic`.
- **Paranoid** (`--paranoid`) — user namespaces off, ptrace off, Bluetooth off, TCP trims.
- **Tor kill-switch** (`umbra-torswitch on`) — all traffic through Tor, leaks fail closed. Off by default.

## Build

Needs Linux (native, WSL2, or Docker). From Windows:
```bash
./build-in-docker.sh          # -> out/umbra-os-amd64.hybrid.iso
```
On Debian/Ubuntu/WSL2:
```bash
sudo apt install live-build
sudo ./build.sh
```

## Install & harden

1. Boot ISO → run installer → **"Guided – encrypted LVM"** (LUKS2), long passphrase (7+ diceware words).
2. First boot:
   ```bash
   sudo umbra-harden-install.sh                    # baseline post-install
   sudo umbra-harden-install.sh --hidepid --no-camera --paranoid   # optional extras
   ```
3. Verify:
   ```bash
   sudo umbra-verify.sh
   sudo lynis audit system      # third-party audit; expect hardening index >= 85
   ```

## Opsec commands (installed to /usr/local/sbin)

| Command | Does |
|---|---|
| `umbra-verify.sh` | Prove ~30 hardening + opsec controls are active |
| `umbra-harden-install.sh` | Second-stage: mounts, USBGuard, AIDE, paranoid/camera/mic toggles |
| `umbra-torswitch on\|off\|status` | Transparent Tor kill-switch (all traffic via Tor; leaks blocked) |
| `umbra-panic` | Emergency: cut network, evict LUKS keys from RAM, hard poweroff |
| `scrub <file>` | Strip metadata (EXIF/document) via MAT2 before sharing |

## Firmware prerequisites (no distro can do these for you)

- Enable **UEFI Secure Boot** (Debian's signed shim works out of the box).
- Set a **firmware/BIOS password**, disable external boot.
- Keep microcode/firmware current (`fwupdmgr`).

## Docs

- [docs/HARDENING.md](docs/HARDENING.md) — every hardening control, its rationale, and what it breaks.
- [docs/OPSEC.md](docs/OPSEC.md) — the opsec/anonymity layer, the Tor kill-switch design, and honest limits.

## Deliberate non-goals

- **Not Tails.** Umbra is installed and persistent, not amnesic. Use Tails for leave-no-trace.
- **Not Whonix.** Same-host transparent Tor is weaker than an isolated Tor gateway. See OPSEC.md.
- **Not anti-forensics of the disk.** `umbra-panic` protects the *key in RAM*, relying on LUKS at rest.

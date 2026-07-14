# Umbra OS — Red Team Edition

A pentesting / red-teaming build of Umbra OS: the same hardened, opsec-focused
base, plus a curated offensive toolkit. It keeps Umbra's privacy plumbing (MAC
randomization, Tor/WireGuard kill-switches, metadata scrubbing, the `umbra`
command center) so your **own** machine stays quiet while you work.

> ⚠️ **Authorized use only.** These tools are for penetration testing, CTFs,
> security research, and training **with explicit permission** on systems you own
> or are authorized to test. Unauthorized access to computer systems is illegal.
> The live system shows this notice at login (`/etc/issue`, `/etc/motd`).

## What's included

**From Debian** (installed via the package list, always present):

| Area | Tools |
|------|-------|
| Recon / scanning | `nmap` `masscan` `whatweb` `wafw00f` `dnsrecon` `dnsenum` `whois` `dnsutils` |
| Web app testing | `gobuster` `ffuf` `dirb` `sqlmap` |
| Traffic / MITM | `wireshark` `tshark` `tcpdump` `bettercap` |
| Wireless | `aircrack-ng` `reaver` |
| Password / hashes | `hydra` `medusa` `john` `hashcat` `hashid` `crunch` `cewl` |
| SMB / AD | `smbclient` `impacket` |
| Pivoting | `proxychains4` `socat` |
| Forensics / stego | `binwalk` `foremost` `exiftool` `steghide` |

**Marquee tools not in Debian** (added by the `0400-umbra-redteam` hook via their
own native installers — deliberately **not** the Kali repo, which conflicts with
Debian stable and breaks dependency resolution):

- **Metasploit Framework** — Rapid7's official apt repo (self-contained omnibus)
- **searchsploit** (Exploit-DB) — git clone → `/opt/exploitdb`
- **nikto** — git clone → `/opt/nikto` (`nikto` launcher)
- **Responder** — git clone → `/opt/Responder` (`responder` launcher)
- **enum4linux** — git clone → `/opt/enum4linux`
- **wpscan** — RubyGems
- **netexec** (modern CrackMapExec) — pipx
- **rockyou** wordlist — `/usr/share/wordlists/rockyou.txt`

Each marquee install is independent and graceful: if the network drops one, that
single tool is skipped and everything else still builds.

## Building it

**With CI (recommended — reliable network for the tool downloads):**

Actions → **build-iso** → *Run workflow* → set **edition = redteam**. The run
uploads `umbra-os-redteam-amd64.hybrid.iso` as a build artifact.

**Locally** (Docker, on any OS):

```bash
docker run --privileged --dns 1.1.1.1 --dns 8.8.8.8 \
  -e UMBRA_EDITION=redteam -v "$PWD":/src debian:trixie \
  bash /src/container-build.sh
# → out/umbra-os-redteam-amd64.hybrid.iso
```

Or on a Debian/Ubuntu host with live-build:

```bash
sudo UMBRA_EDITION=redteam ./build.sh
```

## Relationship to the base edition

- Base and Red Team share one config tree. The redteam package list and hook ship
  as `*.disabled` and are switched on only when `UMBRA_EDITION=redteam`.
- **hardened_malloc** is disabled on the Red Team image (some offensive tools trip
  its hardened allocator). Re-enable any time with `umbra hardened-malloc`.
- Everything else — kernel hardening, sysctls, AppArmor, nftables default-deny,
  auditd, the `umbra` command center — is identical to the base edition. See
  [HARDENING.md](HARDENING.md) and [OPSEC.md](OPSEC.md).

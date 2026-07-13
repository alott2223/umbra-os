# Umbra OS — opsec / anonymity layer

This document covers the privacy and operational-security controls that sit on top of the system
hardening in [HARDENING.md](HARDENING.md). It is deliberately blunt about what each control does
**and does not** protect against — false confidence is the enemy of opsec.

## Threat-model framing

Opsec controls defend against three different adversaries; keep them separate:

1. **Passive network/local observers** (coffee-shop Wi-Fi, ISP, LAN neighbors) — defeated by MAC
   randomization, encrypted DNS, no multicast leaks, IPv6 privacy addresses. Umbra does this by default.
2. **Web trackers / fingerprinters** — reduced by the hardened Firefox profile and cookie
   partitioning. Reduced, not eliminated: real anonymity from web tracking needs the Tor Browser.
3. **A global or targeted adversary who wants to deanonymize you** — this is Tor/Tails/Whonix
   territory. Umbra's Tor kill-switch helps prevent *leaks*, but same-host torification is **not**
   equivalent to the Tor Browser on Whonix. Do not bet your safety on it.

## Passive-observer defenses (on by default)

### MAC address randomization
`/etc/NetworkManager/conf.d/00-umbra-mac-randomization.conf`

- Wi-Fi **scans** use a random MAC, so you don't broadcast your real hardware address just by having
  Wi-Fi on.
- Each connection uses a MAC that is **randomized but stable per network+boot** (`stable` +
  a `stable-id` that includes `${BOOT}`), so captive portals and DHCP leases work, but networks
  can't trivially correlate you across time.
- Want a fresh MAC on every single connection? Set `cloned-mac-address=random` (breaks some captive
  portals). `macchanger` is also installed for manual control.

### DHCP anonymity (RFC 7844)
`01-umbra-privacy.conf` disables sending your hostname and vendor/client-id in DHCP, so the network
learns as little as possible about the device.

### Encrypted DNS (DoT)
`/etc/systemd/resolved.conf.d/10-umbra-dot.conf` forces **DNS-over-TLS to Quad9** (no-logging,
Switzerland), with DNSSEC and **LLMNR/mDNS disabled** so you don't multicast your queries and
hostname to the whole LAN. Swap the `DNS=` line for Mullvad (`194.242.2.2#dns.mullvad.net`) or your
own resolver freely.

### Generic hostname
The machine is named `umbra`, not something unique — a unique hostname is a cross-network
fingerprint (and leaks via DHCP/mDNS on misconfigured setups).

### Clock in UTC
Your local timezone is a fingerprint. Umbra defaults to UTC; change it only if you accept that.

## Browser hardening
`/etc/firefox-esr/umbra.js` (applied system-wide via Firefox autoconfig) is a pragmatic
arkenfox-style subset: telemetry locked off, `resistFingerprinting`, first-party isolation +
total cookie protection, HTTPS-only, WebRTC disabled (no IP leak), DoH, prefetch/predictor off.
It reduces tracking but is **not** the Tor Browser — for anonymity use the Tor Browser bundle.

## Metadata scrubbing
`mat2` is installed and wrapped as `scrub <file>`: strip EXIF from photos and metadata from
documents **before** you share them. Metadata (GPS, author, device serials, timestamps) is one of
the most common self-deanonymization vectors.

## The Tor kill-switch (opt-in)

`umbra-torswitch {on|off|status}` + `/etc/umbra/tor-killswitch.nft` + `/etc/tor/torrc.d/umbra-transparent.conf`

**On:** starts Tor, then loads an nftables ruleset that:
- allows the `debian-tor` user's own traffic out (so Tor can reach the network),
- redirects all other TCP into Tor's `TransPort` (9040) and all DNS into Tor's `DNSPort` (5353),
- **drops everything else** (UDP incl. QUIC, ICMP, anything non-torifiable).

The point of the word *kill-switch*: if Tor stops, the ruleset still drops non-Tor traffic, so you
**fail closed** — no silent fallback to the clear net. Verify with `umbra-torswitch status`, which
queries `check.torproject.org` through the tunnel.

**Off:** flushes the ruleset, restores `/etc/nftables.conf`, stops Tor.

### Honest limits of same-host torification
- Running Tor and your apps on the **same machine** means a compromised app can potentially see your
  real IP before redirection, or correlate via other side channels. An isolated Tor **gateway**
  (Whonix) is stronger because the workstation physically cannot learn its own public IP.
- Transparent torification does not give you the Tor Browser's anti-fingerprinting. For strong
  anonymity, run the **Tor Browser** (still routed through the kill-switch) rather than plain Firefox.
- This is a leak-prevention and censorship-resistance tool, not an anonymity guarantee against a
  determined adversary. If your life depends on it, use **Tails** (amnesic) or **Whonix**.

## Panic wipe
`umbra-panic` is for the "someone is taking my laptop right now" moment. It cuts the network, then
`cryptsetup luksSuspend`s active encrypted volumes (evicting the **master key from kernel RAM**),
flushes swap, drops caches, and forces an immediate `sysrq` poweroff. Result: a powered-off machine
whose disk is LUKS-encrypted at rest and whose key is no longer in memory — defeating a cold-boot /
RAM-capture grab. It does **not** shred the disk; your data is intact but locked.

## Operational hygiene the OS can't do for you
- Use a **long diceware LUKS passphrase**; the disk key is the whole ballgame at rest.
- Don't reuse identities/logins across your Tor and clear-net sessions.
- Turn off Wi-Fi/Bluetooth radios when not in use (`--paranoid` disables Bluetooth entirely).
- Assume metadata everywhere; `scrub` before sharing.
- The Tor kill-switch protects the network path, not your behavior — logging into a personal account
  over Tor deanonymizes you regardless.

## Optional escalation
If you want closer to Tails/Whonix:
- Run Umbra as a **Whonix workstation** behind a Whonix gateway VM (best of both).
- Boot the ISO in **live mode** and never install → approximates amnesia (writes go to RAM),
  though it lacks Tails' explicit anti-forensic wipes.

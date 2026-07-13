# Changelog

All notable changes to Umbra OS are documented here.

## v1.2 — "lean shadow"

### Added
- **GitHub Actions CI** — every `v*` tag builds the ISO on a runner (reliable network, so the
  Graphite theme and everything else always build) and publishes it to the matching Release,
  automatically single-file or split-if-over-2GiB.

### Changed
- **Slimmed the image.** Dropped the full GNOME desktop (GNOME Shell, LibreOffice, games — all
  unused since Umbra boots i3) in favour of an explicit, lean X session: Xorg + VM/modern-GPU
  drivers, PipeWire, `lxpolkit`, Thunar, and the settings/theme backends. Result: a smaller
  download, faster boot, and **less attack surface** (fewer packages to ever patch).
- File manager → **Thunar** (`Super+n` / taskbar **Files**); **Settings** taskbar button → a new
  lightweight `umbra-settings` rofi menu (Network / Audio / Displays / Appearance / Bluetooth).
- System-wide GTK dark theme (`/etc/gtk-3.0` + `gtk-4.0`) so apps stay on-brand under i3 without
  GNOME's settings daemon.
- squashfs now uses **xz** compression and drops the apt package indices from the image.

## v1.1 — "sharper shadow"

### Added
- **`umbra tip`** — a daily, deterministic operational-security tip (22 in the set;
  `umbra tip --all` browses them). Also surfaced as a desktop notification a few seconds
  after login.
- **`umbra vpn <conf>` / `umbra vpn off`** — a WireGuard kill-switch: brings the tunnel up and
  installs an nftables egress lock so traffic can leave *only* through the VPN interface (fails
  closed, like the Tor kill-switch).
- **`umbra encrypt <file>` / `umbra decrypt <file>`** — quick passphrase file encryption with
  [age](https://age-encryption.org/).
- **Branded lock screen** (`umbra-lock`) — i3lock over the Umbra wallpaper instead of the plain
  black-and-green default. Bound to `Super+Shift+x` and the idle auto-lock.
- **Rofi power menu** (`umbra-powermenu`) — Lock / Logout / Suspend / Reboot / Shut down, themed
  to match. Bound to `Super+Escape` and the taskbar power button.
- **Battery indicator** in polybar (shows only on hardware with a battery).
- **CLI toolkit**: neovim, tmux, ripgrep, fzf, ncdu, htop, zathura, tree, jq, age.

### Changed
- **hardened_malloc is now guaranteed.** It is pre-built as a **portable** shared object
  (`CONFIG_NATIVE=false`, so no illegal-instruction crashes on other CPUs) and vendored into the
  image, so it no longer depends on the build host's network. The premium hook simply enables the
  system-wide preload.
- The premium build hook no longer needs a compiler; the image ships without a build toolchain.
- Taskbar power button and lock now use the new rofi power menu / branded lock.

### Fixed
- (from v1.0.x) live-kernel command line now carries the full KSPP hardening flag set
  (`lockdown=confidentiality`, `mitigations=auto,nosmt`, …), not just the installed system.
- `/etc/sudoers.d` permissions (no longer world-writable).
- AppArmor and systemd-resolved are force-started at boot via a oneshot service.
- `umbra-verify.sh` counter bug that produced a phantom `kptr_restrict` failure.

## v1.0 — initial public release
- Debian trixie live-build base, KSPP-hardened kernel, ~45 sysctls, AppArmor, nftables
  default-deny, auditd (immutable), USBGuard, LUKS-ready.
- Opsec layer: MAC randomization, DNS-over-TLS, no LLMNR/mDNS, hardened Firefox, Tor transparent
  kill-switch, panic wipe, metadata scrubbing.
- i3 tiling desktop (polybar top bar + mouse-drivable taskbar, rofi, picom, alacritty), lightdm
  autologin, Umbra eclipse branding.
- `umbra` security command center; AIDE, Lynis, rkhunter, chkrootkit, ClamAV.

#!/bin/bash
# Umbra OS — Tor transparent-proxy kill-switch.
#
#   umbra-torswitch on       route ALL traffic through Tor; drop anything that can't be
#   umbra-torswitch off      restore the normal firewall and direct networking
#   umbra-torswitch status   show current state and confirm Tor routing
#
# When ON, if Tor stops the network fails closed (no clear-net leak).
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run as root (sudo umbra-torswitch $*)" >&2; exit 1; }

KS=/etc/umbra/tor-killswitch.nft
NORMAL=/etc/nftables.conf
STATE=/run/umbra-torswitch.state

usage() { echo "usage: umbra-torswitch {on|off|status}" >&2; exit 1; }
[[ $# -eq 1 ]] || usage

case "$1" in
  on)
    command -v tor >/dev/null || { echo "tor not installed" >&2; exit 1; }
    TOR_UID="$(id -u debian-tor 2>/dev/null || id -u tor 2>/dev/null || true)"
    [[ -n "$TOR_UID" ]] || { echo "tor system user not found" >&2; exit 1; }

    echo "==> starting tor"
    systemctl start tor.service
    # wait for the transparent ports to come up
    for _ in $(seq 1 20); do
        ss -ltn 2>/dev/null | grep -q '127.0.0.1:9040' && break
        sleep 0.5
    done

    echo "==> installing kill-switch firewall (Tor uid=$TOR_UID)"
    # substitute the real tor uid into the ruleset before loading
    sed "s/^define TOR_UID = .*/define TOR_UID = $TOR_UID/" "$KS" | nft -f -

    echo "on" > "$STATE"
    echo "Tor kill-switch ACTIVE. All traffic is routed through Tor; leaks fail closed."
    echo "Verify with: umbra-torswitch status"
    ;;

  off)
    echo "==> restoring normal firewall"
    nft flush ruleset
    nft -f "$NORMAL"
    echo "==> stopping tor"
    systemctl stop tor.service || true
    rm -f "$STATE"
    echo "Tor kill-switch OFF. Networking is direct again."
    ;;

  status)
    if [[ -f "$STATE" ]]; then
        echo "state: ON (kill-switch active)"
    else
        echo "state: OFF"
    fi
    echo -n "tor service: "; systemctl is-active tor.service || true
    if [[ -f "$STATE" ]]; then
        echo "checking exit via Tor..."
        if command -v curl >/dev/null; then
            # With the kill-switch on, this TCP connection is transparently torified.
            curl -s --max-time 20 https://check.torproject.org/api/ip || echo "  (could not reach check.torproject.org)"
            echo
        fi
    fi
    ;;

  *) usage ;;
esac

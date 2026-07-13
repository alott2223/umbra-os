#!/bin/bash
# Umbra OS — launch the top info bar and the bottom taskbar.
killall -q polybar 2>/dev/null
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done
polybar --reload top    -c /etc/polybar/config.ini &
polybar --reload bottom -c /etc/polybar/config.ini &

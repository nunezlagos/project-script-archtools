#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 1; done

# Start minimal top and bottom bars using separate configs
polybar top -c ~/.config/polybar/top_bar.ini &
polybar bottom -c ~/.config/polybar/bottom_bar.ini &

echo "Polybar (top/bottom) launched with split configs"
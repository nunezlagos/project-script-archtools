#!/usr/bin/env sh
# Terminate already running bar instances
killall -q polybar
## Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
polybar primary -c ~/.config/polybar/workspace.ini &
polybar main_primary -c ~/.config/polybar/current.ini &
polybar main_secondary -c ~/.config/polybar/current.ini &


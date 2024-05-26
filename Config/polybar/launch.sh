#!/usr/bin/env sh

## Add this to your wm startup file.

# Terminate already running bar instances
killall -q polybar

## Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

## Launch

## Left bar

polybar secondary -c ~/.config/polybar/current.ini &
#polybar terciary -c ~/.config/polybar/current.ini &

#polybar quinary -c ~/.config/polybar/current.ini &

## Right bar
polybar top -c ~/.config/polybar/current.ini &
polybar quaternary -c ~/.config/polybar/current.ini &
polybar music -c ~/.config/polybar/current.ini &

## Center bar
polybar primary -c ~/.config/polybar/workspace.ini &


## Bottom bar
polybar bottom -c ~/.config/polybar/workspace.ini &
polybar log -c ~/.config/polybar/current.ini &
#bOKITA LO MAS GRANDE
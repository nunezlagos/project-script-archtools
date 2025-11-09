#!/usr/bin/env bash
set -euo pipefail

# Minimal control center with Rofi
# Add simple system actions at the end, separated by a blank line.
CHOICE=$(printf "Internet\nAudio\nWallpapers\nDevices\n\nSuspend\nReboot\nPoweroff\nExit" | rofi -dmenu -i -p "Control" -theme ~/.config/rofi/config.rasi)

case "${CHOICE:-}" in
  Internet)
    if command -v nm-connection-editor >/dev/null 2>&1; then
      GTK_THEME=Adwaita:dark nm-connection-editor &
    else
      GTK_THEME=Adwaita:dark nm-applet &
    fi
    ;;
  Audio)
    GTK_THEME=Adwaita:dark pavucontrol &
    ;;
  Wallpapers)
    ~/.config/polybar/scripts/wallpaper.sh &
    ;;
  Devices)
    GTK_THEME=Adwaita:dark udiskie --tray &
    ;;
  Suspend)
    systemctl suspend &
    ;;
  Reboot)
    systemctl reboot &
    ;;
  Poweroff)
    systemctl poweroff &
    ;;
  Exit) ;;
  *) ;;
esac
#!/usr/bin/env bash
set -euo pipefail

# Minimal control center with Rofi
CHOICE=$(printf "Internet\nAudio\nWallpapers\nDevices\nExit" | rofi -dmenu -p "Control" -theme ~/.config/rofi/config.rasi)

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
  Exit) ;;
  *) ;;
esac
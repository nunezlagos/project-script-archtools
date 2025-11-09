#!/usr/bin/env bash
set -euo pipefail

# Centro de control mínimo con Rofi
CHOICE=$(printf "Internet\nAudio\nWallpapers\nDispositivos\nSalir" | rofi -dmenu -p "Control" -theme ~/.config/rofi/config.rasi)

case "${CHOICE:-}" in
  Internet)
    if command -v nm-connection-editor >/dev/null 2>&1; then
      nm-connection-editor &
    else
      nm-applet &
    fi
    ;;
  Audio)
    pavucontrol &
    ;;
  Wallpapers)
    ~/.config/polybar/scripts/wallpaper.sh &
    ;;
  Dispositivos)
    udiskie --tray &
    ;;
  *) ;;
esac
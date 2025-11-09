#!/usr/bin/env bash
set -euo pipefail

# Minimal control center with Rofi

confirm(){
  local action="$1"
  local ans
  ans=$(printf "Cancel\nConfirm" | rofi -dmenu -i -p "$action?" -theme ~/.config/rofi/config.rasi)
  [[ "$ans" == "Confirm" ]]
}

audio_menu(){
  local items="Pavucontrol"
  command -v helvum >/dev/null 2>&1 && items="$items\nHelvum"
  command -v qpwgraph >/dev/null 2>&1 && items="$items\nQpwgraph"
  local pick=$(printf "%s\n" "$items" | rofi -dmenu -i -p "Audio" -theme ~/.config/rofi/config.rasi)
  case "$pick" in
    Pavucontrol) GTK_THEME=Adwaita:dark pavucontrol & ;;
    Helvum) GTK_THEME=Adwaita:dark helvum & ;;
    Qpwgraph) GTK_THEME=Adwaita:dark qpwgraph & ;;
    *) ;; 
  esac
}

CHOICE=$(printf "Internet\nAudio\nWallpapers\nDevices\n\nSuspend\nReboot\nPoweroff\nExit" | rofi -dmenu -i -p "Control" -theme ~/.config/rofi/config.rasi)

case "${CHOICE:-}" in
  Internet)
    if command -v nmcli >/dev/null 2>&1; then
      bash ~/.config/polybar/scripts/wifi.sh &
    else
      if command -v nm-connection-editor >/dev/null 2>&1; then
        GTK_THEME=Adwaita:dark nm-connection-editor &
      else
        GTK_THEME=Adwaita:dark nm-applet &
      fi
    fi
    ;;
  Audio)
    audio_menu
    ;;
  Wallpapers)
    if command -v nitrogen >/dev/null 2>&1; then
      GTK_THEME=Adwaita:dark nitrogen &
    else
      ~/.config/polybar/scripts/wallpaper.sh &
    fi
    ;;
  Devices)
    bash ~/.config/polybar/scripts/devices.sh &
    ;;
  Suspend)
    if confirm "Suspend"; then systemctl suspend & fi
    ;;
  Reboot)
    if confirm "Reboot"; then systemctl reboot & fi
    ;;
  Poweroff)
    if confirm "Poweroff"; then systemctl poweroff & fi
    ;;
  Exit) ;;
  *) ;;
esac
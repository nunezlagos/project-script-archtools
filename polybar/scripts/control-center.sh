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
  local items
  items="Pavucontrol\x00icon\x1faudio-card"
  if command -v helvum >/dev/null 2>&1; then
    items="$items\nHelvum\x00icon\x1faudio-card"
  fi
  if command -v qpwgraph >/dev/null 2>&1; then
    items="$items\nQpwgraph\x00icon\x1faudio-card"
  fi
  local pick=$(printf "%s\n" "$items" | rofi -dmenu -i -p "Audio" -show-icons -theme ~/.config/rofi/config.rasi)
  case "$pick" in
    Pavucontrol) GTK_THEME=Adwaita:dark pavucontrol & ;;
    Helvum) GTK_THEME=Adwaita:dark helvum & ;;
    Qpwgraph) GTK_THEME=Adwaita:dark qpwgraph & ;;
    *) ;; 
  esac
}

CHOICE=$(cat <<'EOF' | rofi -dmenu -i -p "Control" -show-icons -theme ~/.config/rofi/config.rasi
Network\x00icon\x1fnetwork-wireless
Audio\x00icon\x1faudio-volume-high
Wallpapers\x00icon\x1fimage-x-generic
Devices\x00icon\x1fcomputer
Suspend\x00icon\x1fsystem-suspend
Reboot\x00icon\x1fsystem-reboot
Poweroff\x00icon\x1fsystem-shutdown
Exit\x00icon\x1fsystem-log-out
EOF
)

case "${CHOICE:-}" in
  Network)
    if command -v nm-connection-editor >/dev/null 2>&1; then
      GTK_THEME=Adwaita:dark nm-connection-editor &
    elif command -v nm-applet >/dev/null 2>&1; then
      GTK_THEME=Adwaita:dark nm-applet &
    elif command -v nmcli >/dev/null 2>&1; then
      bash ~/.config/polybar/scripts/wifi.sh &
    else
      bash ~/.config/polybar/scripts/wifi.sh &
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
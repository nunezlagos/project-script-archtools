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
  items="  Pavucontrol"
  if command -v helvum >/dev/null 2>&1; then
    items="$items\n  Helvum"
  fi
  if command -v qpwgraph >/dev/null 2>&1; then
    items="$items\n  Qpwgraph"
  fi
  local pick=$(printf "%s\n" "$items" | rofi -dmenu -i -p "Audio" -theme ~/.config/rofi/config.rasi)
  case "$pick" in
    *Pavucontrol*) GTK_THEME=Adwaita:dark ~/.config/polybar/scripts/open_float.sh Pavucontrol pavucontrol ;;
    *Helvum*) GTK_THEME=Adwaita:dark ~/.config/polybar/scripts/open_float.sh helvum helvum ;;
    *Qpwgraph*) GTK_THEME=Adwaita:dark ~/.config/polybar/scripts/open_float.sh qpwgraph qpwgraph ;;
    *) ;; 
  esac
}

CHOICE=$(cat <<'EOF' | rofi -dmenu -i -p "Control" -theme ~/.config/rofi/config.rasi
  Network
  Audio
  Wallpapers
  Devices
  Suspend
  Reboot
  Poweroff
  Exit
EOF
)

case "${CHOICE:-}" in
  *Network*)
    if command -v nm-connection-editor >/dev/null 2>&1; then
      GTK_THEME=Adwaita:dark ~/.config/polybar/scripts/open_float.sh nm-connection-editor nm-connection-editor
    elif command -v nm-applet >/dev/null 2>&1; then
      GTK_THEME=Adwaita:dark ~/.config/polybar/scripts/open_float.sh nm-applet nm-applet
    elif command -v nmcli >/dev/null 2>&1; then
      bash ~/.config/polybar/scripts/wifi.sh &
    else
      bash ~/.config/polybar/scripts/wifi.sh &
    fi
    ;;
  *Audio*)
    audio_menu
    ;;
  *Wallpapers*)
    ~/.config/polybar/scripts/wallpaper_tui.sh &
    ;;
  *Devices*)
    bash ~/.config/polybar/scripts/devices.sh &
    ;;
  *Suspend*)
    if confirm "Suspend"; then systemctl suspend & fi
    ;;
  *Reboot*)
    if confirm "Reboot"; then systemctl reboot & fi
    ;;
  *Poweroff*)
    if confirm "Poweroff"; then systemctl poweroff & fi
    ;;
  *Exit*) ;;
  *) ;;
esac
#!/usr/bin/env bash
set -euo pipefail

# Calendar launcher with Chilean locale if available

launch_gsimplecal(){
  LC_TIME=es_CL.UTF-8 gsimplecal &
}

launch_zenity(){
  LC_TIME=es_CL.UTF-8 zenity --calendar --width=320 --height=220 --title="Calendario" &
}

launch_rofi_cal(){
  cal_out=$(LC_TIME=es_CL.UTF-8 cal | sed 's/^/  /')
  printf "%s\n" "$cal_out" | rofi -dmenu -p "Calendar" -theme ~/.config/rofi/config.rasi >/dev/null 2>&1 || true
}

if command -v gsimplecal >/dev/null 2>&1; then
  launch_gsimplecal
elif command -v zenity >/dev/null 2>&1; then
  launch_zenity
else
  launch_rofi_cal
fi
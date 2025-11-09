#!/usr/bin/env bash
set -euo pipefail

# Calendar launcher with Chilean locale if available

launch_gsimplecal(){
  # Regla temporal para flotar y centrar
  bspc rule -a gsimplecal -o state=floating center=true
  bspc rule -a Gsimplecal -o state=floating center=true
  LC_TIME=es_CL.UTF-8 gsimplecal &
  sleep 0.8
  bspc rule -r gsimplecal || true
  bspc rule -r Gsimplecal || true
}

launch_zenity(){
  bspc rule -a Zenity -o state=floating center=true
  LC_TIME=es_CL.UTF-8 zenity --calendar --width=360 --height=260 --title="Calendario" &
  sleep 0.8
  bspc rule -r Zenity || true
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
#!/usr/bin/env bash
set -euo pipefail

# Calendar launcher with Chilean locale if available

launch_yad(){
  # YAD calendar (GTK) with larger size; respects dark theme
  bspc rule -a yad -o state=floating center=true
  LC_TIME=es_CL.UTF-8 yad --calendar \
    --width=560 --height=440 \
    --title="Calendario" --no-buttons --borders=12 &
  sleep 0.8
  bspc rule -r yad || true
}

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
  LC_TIME=es_CL.UTF-8 zenity --calendar --width=560 --height=440 --title="Calendario" &
  sleep 0.8
  bspc rule -r Zenity || true
}

launch_kitty_calcurse(){
  # Interactive TUI calendar inside Kitty, floating and centered
  bspc rule -a CalendarPopup -o state=floating center=true
  LC_TIME=es_CL.UTF-8 kitty --class CalendarPopup -T "Calendario" \
    -o remember_window_size=no \
    -o initial_window_width=720 \
    -o initial_window_height=520 \
    -o background_opacity=1.0 \
    -o background=#0f111a \
    -o foreground=#c0caf5 \
    -e bash -lc 'env TERM=xterm-256color calcurse || cal' &
  sleep 1
  bspc rule -r CalendarPopup || true
}

launch_rofi_cal(){
  cal_out=$(LC_TIME=es_CL.UTF-8 cal | sed 's/^/  /')
  printf "%s\n" "$cal_out" | rofi -dmenu -p "Calendar" -theme ~/.config/rofi/config.rasi >/dev/null 2>&1 || true
}

if command -v calcurse >/dev/null 2>&1 && command -v kitty >/dev/null 2>&1; then
  launch_kitty_calcurse
elif command -v yad >/dev/null 2>&1; then
  launch_yad
elif command -v gsimplecal >/dev/null 2>&1; then
  launch_gsimplecal
elif command -v zenity >/dev/null 2>&1; then
  launch_zenity
else
  launch_rofi_cal
fi
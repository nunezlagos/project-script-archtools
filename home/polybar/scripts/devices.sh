#!/usr/bin/env bash
set -euo pipefail

# Minimal devices (mount/unmount) via rofi + udisksctl, usando glifos en lugar de icon markup

list_devices(){
  lsblk -rpno NAME,TYPE,MOUNTPOINT | awk '{name=$1; type=$2; mp=$3; if(type=="part"||type=="rom"||type=="disk"){ if(mp=="") mp="(not mounted)"; printf "  %s  %s\n", name, mp}}'
}

## Flotar y centrar la ventana de Rofi temporalmente
bspc rule -a Rofi -o state=floating center=true
CHOICE=$(printf "%s\n" "$(list_devices)" | rofi -dmenu -i -p "Devices" -theme ~/.config/rofi/config.rasi)
bspc rule -r Rofi || true
[[ -z "${CHOICE:-}" ]] && exit 0

dev=$(echo "$CHOICE" | awk '{print $1}')
mp=$(echo "$CHOICE" | awk '{print $2}')

if [[ "$mp" == "(not" ]]; then
  udisksctl mount -b "$dev" && notify-send "Devices" "Mounted $dev" || notify-send "Devices" "Failed to mount $dev" || true
else
  udisksctl unmount -b "$dev" && notify-send "Devices" "Unmounted $dev" || notify-send "Devices" "Failed to unmount $dev" || true
fi
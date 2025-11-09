#!/usr/bin/env bash
set -euo pipefail

# Minimal Wi‑Fi picker using nmcli + rofi (case-insensitive)

wifi_dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')
if [[ -z "${wifi_dev:-}" ]]; then
  notify-send "Wi‑Fi" "No wifi device found" || true
  exit 0
fi

menu_list=$(nmcli -t -f SSID,SECURITY device wifi list ifname "$wifi_dev" | awk -F: '{ssid=$1; sec=$2; if (ssid=="") ssid="<hidden>"; printf "%s  [%s]\n", ssid, sec} ' | sort -u)

CHOICE=$(printf "Disconnect\n%s\n" "$menu_list" | rofi -dmenu -i -p "Wi‑Fi" -theme ~/.config/rofi/config.rasi)

[[ -z "${CHOICE:-}" ]] && exit 0

if [[ "$CHOICE" == "Disconnect" ]]; then
  nmcli device disconnect "$wifi_dev" && notify-send "Wi‑Fi" "Disconnected" || true
  exit 0
fi

ssid=${CHOICE%%  *}
security=$(echo "$CHOICE" | sed -E 's/^.*\[(.*)\].*$/\1/')

if [[ "$security" == "--" || "$security" == "NONE" || "$security" == "" ]]; then
  nmcli device wifi connect "$ssid" ifname "$wifi_dev" && notify-send "Wi‑Fi" "Connected to $ssid" || notify-send "Wi‑Fi" "Failed to connect $ssid" || true
else
  pass=$(rofi -dmenu -password -p "Password for $ssid" -theme ~/.config/rofi/config.rasi || true)
  [[ -z "${pass:-}" ]] && exit 0
  nmcli device wifi connect "$ssid" ifname "$wifi_dev" password "$pass" && notify-send "Wi‑Fi" "Connected to $ssid" || notify-send "Wi‑Fi" "Failed to connect $ssid" || true
fi
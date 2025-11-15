#!/usr/bin/env bash
set -euo pipefail

# Minimal Wi‑Fi picker using nmcli + rofi (case-insensitive)

wifi_dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')
if [[ -z "${wifi_dev:-}" ]]; then
  notify-send "Wi‑Fi" "No wifi device found" || true
  exit 0
fi

nmcli device wifi rescan ifname "$wifi_dev" >/dev/null 2>&1 || true

wifi_radio_state=$(nmcli -t -f WIFI general | awk -F: '{print $1}')

# Build list: control options + networks with signal/bars and lock icon
menu_list=$(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL,BARS device wifi list ifname "$wifi_dev" |
  awk -F: '
  {
    inuse=$1; ssid=$2; sec=$3; sig=$4; bars=$5;
    if(ssid=="") ssid="<hidden>";
    lock=(sec=="--"||sec=="NONE")?" ":"🔒";
    mark=(inuse=="*")?"★":" ";
    printf "%s %s  [%s]  %3s%% %s %s\n", mark, ssid, sec, sig, bars, lock;
  }' |
  awk '!seen[$2]++')

CHOICE=$(printf "Toggle Wi‑Fi (%s)\nRescan\nDisconnect\n%s\n" "$wifi_radio_state" "$menu_list" | rofi -dmenu -i -p "Wi‑Fi" -theme ~/.config/rofi/config.rasi)

[[ -z "${CHOICE:-}" ]] && exit 0

if [[ "$CHOICE" == Toggle* ]]; then
  if [[ "$wifi_radio_state" == "enabled" ]]; then
    nmcli radio wifi off && notify-send "Wi‑Fi" "Wi‑Fi disabled" || true
  else
    nmcli radio wifi on && notify-send "Wi‑Fi" "Wi‑Fi enabled" || true
  fi
  exit 0
fi

if [[ "$CHOICE" == "Rescan" ]]; then
  nmcli device wifi rescan ifname "$wifi_dev" && notify-send "Wi‑Fi" "Rescanned networks" || true
  exit 0
fi

if [[ "$CHOICE" == "Disconnect" ]]; then
  nmcli device disconnect "$wifi_dev" && notify-send "Wi‑Fi" "Disconnected" || true
  exit 0
fi

ssid=$(echo "$CHOICE" | awk '{print $2}')
security=$(echo "$CHOICE" | sed -E 's/^.*\[(.*)\].*$/\1/')

if [[ "$security" == "--" || "$security" == "NONE" || "$security" == "" ]]; then
  nmcli device wifi connect "$ssid" ifname "$wifi_dev" && notify-send "Wi‑Fi" "Connected to $ssid" || notify-send "Wi‑Fi" "Failed to connect $ssid" || true
else
  pass=$(rofi -dmenu -password -p "Password for $ssid" -theme ~/.config/rofi/config.rasi || true)
  [[ -z "${pass:-}" ]] && exit 0
  nmcli device wifi connect "$ssid" ifname "$wifi_dev" password "$pass" && notify-send "Wi‑Fi" "Connected to $ssid" || notify-send "Wi‑Fi" "Failed to connect $ssid" || true
fi
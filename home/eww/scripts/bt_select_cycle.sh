#!/usr/bin/env bash
set -euo pipefail

dir=${1:-next}

mapfile -t addrs < <(bluetoothctl devices | awk '{print $2}')
if [[ ${#addrs[@]} -eq 0 ]]; then
  eww update bt_selected_addr=""
  eww update bt_selected_name="Sin dispositivos"
  exit 0
fi

current=$(eww get bt_selected_addr 2>/dev/null || echo "")
idx=0
if [[ -n "$current" ]]; then
  for i in "${!addrs[@]}"; do
    if [[ "${addrs[$i]}" == "$current" ]]; then idx=$i; break; fi
  done
fi

if [[ "$dir" == "next" ]]; then
  next_index=$(( (idx + 1) % ${#addrs[@]} ))
else
  next_index=$(( (idx - 1 + ${#addrs[@]}) % ${#addrs[@]} ))
fi

addr="${addrs[$next_index]}"
name=$(bluetoothctl info "$addr" 2>/dev/null | awk -F': ' '/Name:/ {print $2}' | head -n1)
eww update bt_selected_addr="$addr"
eww update bt_selected_name="${name:-Dispositivo}"
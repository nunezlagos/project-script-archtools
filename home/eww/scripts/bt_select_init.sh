#!/usr/bin/env bash
set -euo pipefail

# Pick first paired device as selection
addr=$(bluetoothctl devices | awk '{print $2}' | head -n1)
name=""
if [[ -n "$addr" ]]; then
  name=$(bluetoothctl info "$addr" 2>/dev/null | awk -F': ' '/Name:/ {print $2}' | head -n1)
fi
eww update bt_selected_addr="$addr"
eww update bt_selected_name="${name:-Dispositivo}"
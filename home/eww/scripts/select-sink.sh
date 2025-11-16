#!/usr/bin/env bash
set -euo pipefail

# List sinks and allow selection via rofi, then set default sink
choice=$(pactl list short sinks | awk '{printf "%s %s\n", $1, $2}' | rofi -dmenu -p "Sinks" || true)
idx=$(awk '{print $1}' <<<"$choice")
if [[ -n "${idx:-}" ]]; then
  pactl set-default-sink "$idx"
  notify-send -u low "Audio" "Default sink set to $choice" 2>/dev/null || true
fi
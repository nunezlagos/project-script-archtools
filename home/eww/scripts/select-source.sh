#!/usr/bin/env bash
set -euo pipefail

# List sources and allow selection via rofi, then set default source
choice=$(pactl list short sources | awk '{printf "%s %s\n", $1, $2}' | rofi -dmenu -p "Sources" || true)
idx=$(awk '{print $1}' <<<"$choice")
if [[ -n "${idx:-}" ]]; then
  pactl set-default-source "$idx"
  notify-send -u low "Audio" "Default source set to $choice" 2>/dev/null || true
fi
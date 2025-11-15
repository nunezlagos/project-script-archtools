#!/usr/bin/env bash
set -euo pipefail

# Remove the highest-numbered desktop on the focused monitor, keep at least 1

max_keep=1
mon="$(bspc query -M -m --names)"
mapfile -t desks < <(bspc query -D -m "$mon" --names)

count=${#desks[@]}
if (( count <= max_keep )); then
  notify-send "Workspaces" "Cannot remove: minimum $max_keep desktop" 2>/dev/null || true
  exit 0
fi

# pick highest numeric name; if non-numeric, remove focused
last="${desks[-1]}"
if [[ "$last" =~ ^[0-9]+$ ]]; then
  bspc desktop -r "$last"
else
  bspc desktop -r "$(bspc query -D -d --names)"
fi

exit 0
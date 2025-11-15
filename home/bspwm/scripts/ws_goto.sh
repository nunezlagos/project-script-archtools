#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
if [[ -z "$target" || ! "$target" =~ ^[1-8]$ ]]; then
  echo "Usage: ws_goto.sh <1-8>" >&2
  exit 1
fi

mon="$(bspc query -M -m --names)"

# Ensure desktops 1..target exist on the focused monitor
for i in $(seq 1 "$target"); do
  if ! bspc query -D -m "$mon" --names | grep -qx "$i"; then
    bspc monitor "$mon" -a "$i"
  fi
done

# Focus target desktop
bspc desktop -f "$target"

exit 0
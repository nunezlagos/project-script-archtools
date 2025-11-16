#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
if [[ -z "$target" || ! "$target" =~ ^[1-9]$ ]]; then
  echo "Uso: ws_goto.sh <1-9>" >&2
  exit 1
fi

mon="$(bspc query -M -m --names)"

# Si el escritorio 'target' existe, enfocarlo. Si no, crear solo el siguiente (máximo+1)
if bspc query -D -m "$mon" --names | grep -qx "$target"; then
  bspc desktop -f "$target"
else
  # Calcular el máximo existente y crear solo el siguiente
  max=$(bspc query -D -m "$mon" --names | sort -n | tail -n1)
  [[ -z "$max" ]] && max=0
  next=$(( max + 1 ))
  bspc monitor "$mon" -a "$next"
  bspc desktop -f "$next"
fi

exit 0
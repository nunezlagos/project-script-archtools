#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
if [[ -z "$target" || ! "$target" =~ ^[1-9]$ ]]; then
  echo "Uso: ws_goto.sh <1-9>" >&2
  exit 1
fi

mon="$(bspc query -M -m --names)"

# Si el escritorio 'target' existe, enfocarlo. Si no, crear secuencialmente hasta 'target'.
if bspc query -D -m "$mon" --names | grep -qx "$target"; then
  bspc desktop -f "$target"
else
  # Calcular el máximo existente y crear  (max+1 .. target)
  max=$(bspc query -D -m "$mon" --names | sort -n | tail -n1)
  [[ -z "$max" ]] && max=0
  for (( i=max+1; i<=target; i++ )); do
    bspc monitor "$mon" -a "$i"
  done
  bspc desktop -f "$target"
fi

exit 0
#!/usr/bin/env bash
set -euo pipefail

# Añade un nuevo workspace (desktop) en el monitor enfocado hasta un máximo de 8.
# Usa nombres numéricos 1..8 para alinearse con bspwmrc y Polybar.

max=8

# Monitor enfocado
mon="$(bspc query -M -m --names)"

# Escritorios existentes en el monitor enfocado
mapfile -t existing < <(bspc query -D -m "$mon" --names)

# Encuentra el primer número libre entre 1..max
new=""
for i in $(seq 1 "$max"); do
  if ! printf '%s\n' "${existing[@]}" | grep -qx "$i"; then
    new="$i"
    break
  fi
done

if [[ -z "$new" ]]; then
  notify-send "Workspaces" "Ya tienes $max escritorios" 2>/dev/null || true
  exit 0
fi

# Crea y enfoca el nuevo escritorio
bspc monitor "$mon" -a "$new"
bspc desktop -f "^$new"

exit 0
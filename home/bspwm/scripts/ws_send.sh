#!/usr/bin/env bash
set -euo pipefail

# Enviar ventana al escritorio N, creando 1..N si faltan en el monitor enfocado
# Uso: ws_send.sh <1-8>

target="${1:-}"
if [[ -z "$target" || ! "$target" =~ ^[1-9]$ ]]; then
  notify-send "WS Send" "Uso: ws_send.sh <1-9>" -u low -t 2000 || true
  exit 1
fi

# Monitor enfocado
mon=$(bspc query -M -m)
if [[ -z "$mon" ]]; then
  notify-send "WS Send" "No hay monitor enfocado" -u critical -t 2500 || true
  exit 1
fi

# Crear secuencialmente todos los faltantes hasta el destino si no existe
if ! bspc query -D -m "$mon" --names | grep -qx "$target"; then
  max=$(bspc query -D -m "$mon" --names | sort -n | tail -n1)
  [[ -z "$max" ]] && max=0
  for (( i=max+1; i<=target; i++ )); do
    bspc monitor "$mon" -a "$i"
  done
  dest="$target"
else
  dest="$target"
fi

# Enviar el nodo (ventana) al escritorio elegido (mantiene el foco actual)
if bspc query -N -n focused >/dev/null; then
  bspc node -d "$dest"
  notify-send "WS Send" "Ventana enviada al escritorio $dest" -u low -t 1500 || true
else
  notify-send "WS Send" "No hay ventana enfocada para enviar" -u low -t 2000 || true
fi
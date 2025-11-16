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

# Asegura que existan escritorios 1..target en el monitor
for i in $(seq 1 "$target"); do
  if ! bspc query -D -m "$mon" | grep -qx "$i"; then
    bspc monitor "$mon" -a "$i"
  fi
done

# Enviar el nodo (ventana) al escritorio destino (mantiene el foco actual)
if bspc query -N -n focused >/dev/null; then
  bspc node -d "$target"
  notify-send "WS Send" "Ventana enviada al escritorio $target" -u low -t 1500 || true
else
  notify-send "WS Send" "No hay ventana enfocada para enviar" -u low -t 2000 || true
fi
#!/usr/bin/env bash
set -euo pipefail

# Detección de mantener Super+Shift+<n> para confirmar envío de ventana al escritorio n
# Uso: ws_hold_send.sh <1-8> press|release

key="${1:-}"
event="${2:-}"

if [[ -z "$key" || ! "$key" =~ ^[1-8]$ ]]; then
  exit 0
fi

stamp_dir="/tmp/ws_hold_send"
mkdir -p "$stamp_dir"
stamp_file="$stamp_dir/$key.stamp"

hold_ms=3000

case "$event" in
  press)
    date +%s%3N > "$stamp_file"
    ;;
  release)
    if [[ -f "$stamp_file" ]]; then
      start=$(cat "$stamp_file")
      end=$(date +%s%3N)
      delta=$(( end - start ))
      rm -f "$stamp_file"
      if (( delta >= hold_ms )); then
        # Confirmación con dunst
        action=$(dunstify -A send:Enviar -A cancel:Cancelar -u normal -t 6000 "Enviar ventana al escritorio $key?") || true
        if [[ "$action" == "send" ]]; then
          "$(dirname "$0")/ws_send.sh" "$key"
        else
          dunstify -u low -t 1500 "Acción cancelada"
        fi
      fi
    fi
    ;;
esac
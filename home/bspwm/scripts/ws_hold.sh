#!/usr/bin/env bash
set -euo pipefail

key="${1:-}"
event="${2:-}"

if [[ -z "$key" || -z "$event" ]]; then
  echo "Usage: ws_hold.sh <1-8> <press|release>" >&2
  exit 1
fi

stamp_file="/tmp/ws_hold_$key"

case "$event" in
  press)
    # Guard against auto-repeat: only set timestamp if not already present
    if [[ ! -f "$stamp_file" ]]; then
      date +%s > "$stamp_file"
    fi
    ;;
  release)
    if [[ -f "$stamp_file" ]]; then
      start_ts=$(cat "$stamp_file" 2>/dev/null || echo 0)
      rm -f "$stamp_file"
      now_ts=$(date +%s)
      held=$(( now_ts - start_ts ))
      if (( held >= 3 )); then
        # Confirm deletion of the focused desktop via dunst
        current="$(bspc query -D -d --names)"
        mapfile -t desks < <(bspc query -D -m --names)
        if (( ${#desks[@]} <= 1 )); then
          notify-send "Workspaces" "No se puede eliminar: mínimo 1 escritorio" 2>/dev/null || true
          exit 0
        fi
        choice=$(dunstify --print \
          -A cancel,Cancelar -A delete,Eliminar \
          "Workspaces" "¿Eliminar escritorio '$current'?" 2>/dev/null || echo cancel)
        if [[ "$choice" == "delete" ]]; then
          bspc desktop -r "$current"
          notify-send "Workspaces" "Escritorio '$current' eliminado" 2>/dev/null || true
        else
          notify-send "Workspaces" "Acción cancelada" 2>/dev/null || true
        fi
      fi
    fi
    ;;
  *)
    echo "Evento inválido: $event" >&2
    exit 1
    ;;
esac

exit 0
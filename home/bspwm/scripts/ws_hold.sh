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
        # Confirm deletion of the numbered desktop that was held
        target="$key"
        if ! bspc query -D -m --names | grep -qx "$target"; then
          exit 0
        fi
        mapfile -t desks < <(bspc query -D -m --names)
        if (( ${#desks[@]} <= 1 )); then
          notify-send "Workspaces" "No se puede eliminar: mínimo 1 escritorio" 2>/dev/null || true
          exit 0
        fi
        # If desktop has windows, warn but allow deletion (bspwm will move or close based on config)
        if bspc query -N -d "$target" >/dev/null; then
          warn="Contiene ventanas"
        else
          warn="Vacío"
        fi
        prompt="¿Eliminar escritorio '$target' ($warn)?"
        if command -v dunstify >/dev/null 2>&1; then
          choice=$(dunstify --print -A cancel,Cancelar -A delete,Eliminar "Workspaces" "$prompt" 2>/dev/null || echo cancel)
        else
          choice=$(printf "Eliminar\nCancelar" | rofi -dmenu -p "$prompt" 2>/dev/null || echo cancel)
        fi
        if [[ "$choice" == "delete" ]]; then
          bspc desktop -r "$target"
          notify-send "Workspaces" "Escritorio '$target' eliminado" 2>/dev/null || true
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
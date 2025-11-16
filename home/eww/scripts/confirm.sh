#!/usr/bin/env bash
set -euo pipefail

action=${1:-}

case "$action" in
  suspend)
    msg="¿Suspender y bloquear sesión?"
    cmd="loginctl lock-session && systemctl suspend"
    ;;
  reboot)
    msg="¿Reiniciar el sistema?"
    cmd="systemctl reboot"
    ;;
  poweroff)
    msg="¿Apagar el sistema?"
    cmd="systemctl poweroff"
    ;;
  *)
    msg="¿Confirmar acción?"
    cmd="echo"
    ;;
esac

eww update confirm_msg="$msg" >/dev/null 2>&1 || true
eww update confirm_cmd="$cmd" >/dev/null 2>&1 || true
eww open --toggle confirm_panel
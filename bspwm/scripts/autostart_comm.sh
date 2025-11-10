#!/usr/bin/env bash
set -euo pipefail

max=8
mon="$(bspc query -M -m --names)"
mapfile -t existing < <(bspc query -D -m "$mon" --names)

new=""
for i in $(seq 1 "$max"); do
  if ! printf '%s\n' "${existing[@]}" | grep -qx "$i"; then
    new="$i"
    break
  fi
done
[[ -z "$new" ]] && new="$max"

bspc monitor "$mon" -a "$new" 2>/dev/null || true

launch_to_desktop() {
  local bin="$1" class="$2" args="${3:-}"
  if command -v "$bin" >/dev/null 2>&1; then
    # Evitar duplicados por nombre de binario o clase
    if ! pgrep -x "$bin" >/dev/null 2>&1 && ! pgrep -x "$class" >/dev/null 2>&1; then
      bspc rule -a "$class" desktop="^$new" follow=off state=floating
      nohup "$bin" $args >/dev/null 2>&1 & disown
      # Quitar la regla para no afectar futuras ventanas
      sleep 1
      bspc rule -r "$class" 2>/dev/null || true
    fi
  fi
}

# Lanzar Slack y Discord en el workspace nuevo, minimizados si el binario lo soporta
launch_to_desktop slack Slack "--start-minimized"
launch_to_desktop discord Discord "--start-minimized"

# OpenVPN: conecta si existe configuración por defecto
VPN_FILE="$HOME/.config/openvpn/default.ovpn"
NM_NAME_FILE="$HOME/.config/openvpn/nm-name"

# Preferir NetworkManager si existe nombre de conexión
if command -v nmcli >/dev/null 2>&1 && [[ -f "$NM_NAME_FILE" ]]; then
  NM_VPN="$(cat "$NM_NAME_FILE" 2>/dev/null || echo "")"
  if [[ -n "$NM_VPN" ]]; then
    nmcli connection up id "$NM_VPN" >/dev/null 2>&1 & disown || true
  fi
fi

# Fallback: openvpn3 o openvpn clásico con perfil por defecto
if command -v openvpn3 >/dev/null 2>&1 && [[ -f "$VPN_FILE" ]]; then
  openvpn3 session-start --config "$VPN_FILE" >/dev/null 2>&1 & disown || true
elif command -v openvpn >/dev/null 2>&1 && [[ -f "$VPN_FILE" ]]; then
  sudo -n openvpn --config "$VPN_FILE" >/dev/null 2>&1 & disown || true
fi

exit 0
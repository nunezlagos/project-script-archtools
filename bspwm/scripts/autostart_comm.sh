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
  local cmd="$1" class="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    if ! pgrep -x "$cmd" >/dev/null 2>&1 && ! pgrep -x "$class" >/dev/null 2>&1; then
      bspc rule -a "$class" desktop="^$new" follow=off state=floating
      "$cmd" & disown
      sleep 1
      bspc rule -r "$class" 2>/dev/null || true
    fi
  fi
}

launch_to_desktop slack Slack
launch_to_desktop discord Discord

# OpenVPN: conecta si existe configuración por defecto
if command -v openvpn3 >/dev/null 2>&1 && [[ -f "$HOME/.config/openvpn/default.ovpn" ]]; then
  openvpn3 session-start --config "$HOME/.config/openvpn/default.ovpn" & disown
fi
if command -v openvpn >/dev/null 2>&1 && [[ -f "$HOME/.config/openvpn/default.ovpn" ]]; then
  sudo -n openvpn --config "$HOME/.config/openvpn/default.ovpn" >/dev/null 2>&1 & disown || true
fi

exit 0
#!/usr/bin/env bash
set -euo pipefail

# Configura LightDM con el greeter GTK, copia CSS y fondo.
# Uso: sudo tools/setup-lightdm.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
ETC_DIR="/etc/lightdm"
SYS_BG="/usr/share/pixmaps/login-bg.png"

ensure_pkg(){
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm lightdm lightdm-gtk-greeter || true
  elif command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y lightdm lightdm-gtk-greeter || true
  fi
}

write_lightdm_conf(){
  sudo mkdir -p "$ETC_DIR"
  local conf="/etc/lightdm/lightdm.conf"
  if [[ -f "$conf" ]]; then
    sudo cp "$conf" "$conf.bak.$(date +%s)" || true
  fi
  sudo tee "$conf" >/dev/null <<'EOF'
[LightDM]
logind-check-graphical=true

[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=bspwm
EOF
}

copy_greeter_files(){
  sudo mkdir -p "$ETC_DIR"
  if [[ -f "$ROOT_DIR/lightdm/lightdm-gtk-greeter.conf" ]]; then
    sudo cp "$ROOT_DIR/lightdm/lightdm-gtk-greeter.conf" "$ETC_DIR/lightdm-gtk-greeter.conf"
  fi
  if [[ -f "$ROOT_DIR/lightdm/lightdm-gtk-greeter.css" ]]; then
    sudo cp "$ROOT_DIR/lightdm/lightdm-gtk-greeter.css" "$ETC_DIR/lightdm-gtk-greeter.css"
  fi
}

install_background(){
  local src_login_1="$ROOT_DIR/wallpaper/login.png"
  local src_oni_1="$ROOT_DIR/wallpaper/onigirl.png"
  if [[ -f "$src_login_1" ]]; then
    sudo install -Dm644 "$src_login_1" "$SYS_BG"
  elif [[ -f "$src_oni_1" ]]; then
    sudo install -Dm644 "$src_oni_1" "$SYS_BG"
  else
    echo "[warn] No se encontró login.png ni onigirl.png; usando fondo por defecto" >&2
  fi
}

enable_service(){
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now lightdm || true
  else
    echo "[info] Habilita LightDM manualmente si tu sistema no usa systemd"
  fi
}

diagnose(){
  echo "=== Diagnóstico rápido ==="
  echo "Greeter instalado:"; dpkg -l 2>/dev/null | grep -E "lightdm-gtk-greeter|lightdm" || true
  echo "Arch Linux (pacman):"; pacman -Qs lightdm 2>/dev/null || true
  echo "Archivo /etc/lightdm/lightdm.conf:"; sudo grep -E "greeter-session|user-session" /etc/lightdm/lightdm.conf 2>/dev/null || true
  echo "Logs de LightDM (últimas 50 líneas):"; sudo journalctl -u lightdm -n 50 --no-pager 2>/dev/null || true
}

main(){
  ensure_pkg
  write_lightdm_conf
  copy_greeter_files
  install_background
  enable_service
  diagnose || true
  echo "[ok] LightDM configurado con greeter GTK, CSS y fondo. Reinicia para probar."
}

main "$@"
#!/bin/bash
set -euo pipefail

# Instala eww (AUR) y despliega configuración desde home/eww

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config/eww"

oneline(){ printf "[eww] %s\n" "$*"; }

oneline "preparando instalación de eww (AUR)"

# Asegurar yay
if ! command -v yay >/dev/null 2>&1; then
  oneline "yay no encontrado; instalando yay (AUR helper)"
  sudo pacman -S --needed --noconfirm git base-devel >/dev/null 2>&1 || true
  tmpdir="/tmp/yay_install_eww"
  rm -rf "$tmpdir" && mkdir -p "$tmpdir"
  chown "$USER_NAME":"$USER_NAME" "$tmpdir" 2>/dev/null || true
  sudo -u "$USER_NAME" bash -c "cd '$tmpdir' && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm" >/dev/null 2>&1 || true
  rm -rf "$tmpdir" || true
fi

if command -v yay >/dev/null 2>&1; then
  oneline "instalando paquete: yay -S --needed --noconfirm eww"
  sudo -u "$USER_NAME" yay -S --needed --noconfirm eww >/dev/null 2>&1 || true
else
  oneline "fallback: pacman -S eww (puede no existir en repos oficiales)"
  sudo pacman -S --noconfirm eww >/dev/null 2>&1 || true
fi

oneline "desplegando configuración en $CONFIG_DIR"
mkdir -p "$CONFIG_DIR/scss"
mkdir -p "$CONFIG_DIR/scripts"
cp -f "$ROOT_DIR/eww/eww.yuck" "$CONFIG_DIR/eww.yuck"
cp -f "$ROOT_DIR/eww/scss/style.scss" "$CONFIG_DIR/scss/style.scss"
cp -f "$ROOT_DIR/eww/scss/_variables.scss" "$CONFIG_DIR/scss/_variables.scss"
cp -f "$ROOT_DIR/eww/scripts/select-sink.sh" "$CONFIG_DIR/scripts/select-sink.sh"
cp -f "$ROOT_DIR/eww/scripts/select-source.sh" "$CONFIG_DIR/scripts/select-source.sh"
cp -f "$ROOT_DIR/eww/scripts/cycle-sink.sh" "$CONFIG_DIR/scripts/cycle-sink.sh"
cp -f "$ROOT_DIR/eww/scripts/cycle-source.sh" "$CONFIG_DIR/scripts/cycle-source.sh"
cp -f "$ROOT_DIR/eww/scripts/confirm.sh" "$CONFIG_DIR/scripts/confirm.sh"
cp -f "$ROOT_DIR/eww/scripts/bt_select_init.sh" "$CONFIG_DIR/scripts/bt_select_init.sh"
cp -f "$ROOT_DIR/eww/scripts/bt_select_cycle.sh" "$CONFIG_DIR/scripts/bt_select_cycle.sh"
chmod +x "$CONFIG_DIR/scripts/select-sink.sh" "$CONFIG_DIR/scripts/select-source.sh" "$CONFIG_DIR/scripts/cycle-sink.sh" "$CONFIG_DIR/scripts/cycle-source.sh" "$CONFIG_DIR/scripts/confirm.sh" "$CONFIG_DIR/scripts/bt_select_init.sh" "$CONFIG_DIR/scripts/bt_select_cycle.sh" 2>/dev/null || true
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR" 2>/dev/null || true

# Instalar fuentes de símbolos para iconos en Eww
FONTS_SRC_DIR="$ROOT_DIR/polybar/fonts"
FONTS_DST_DIR="$HOME_DIR/.local/share/fonts"
mkdir -p "$FONTS_DST_DIR"
for f in "SymbolsNerdFontMono-Regular.ttf" "SymbolsNerdFont-Regular.ttf"; do
  if [[ -f "$FONTS_SRC_DIR/$f" ]]; then
    cp -f "$FONTS_SRC_DIR/$f" "$FONTS_DST_DIR/$f"
  fi
done
fc-cache -f >/dev/null 2>&1 || true

# Arrancar daemon si no está corriendo
if command -v eww >/dev/null 2>&1; then
  oneline "iniciando eww daemon (si no está activo)"
  sudo -u "$USER_NAME" bash -c 'pgrep -x eww >/dev/null || eww daemon' >/dev/null 2>&1 || true
fi

oneline "instalación/config de eww completada"
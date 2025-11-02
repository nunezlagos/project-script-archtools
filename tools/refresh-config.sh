#!/bin/bash
set -euo pipefail

# Refresca configuraciones por componente desde el repo al ~/.config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
USER_NAME=${SUDO_USER:-$USER}
CONFIG_DIR="/home/$USER_NAME/.config"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok(){ echo -e "${GREEN}[✓]${NC} $1"; }
warn(){ echo -e "${YELLOW}[!]${NC} $1"; }
err(){ echo -e "${RED}[✗]${NC} $1"; }

copy_file_if_exists(){
  local src="$1" dest="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    return 0
  fi
  warn "Archivo no encontrado: $src (omitido)"; return 0
}

copy_dir_if_exists(){
  local src="$1" dest="$2"
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -r "$src/"* "$dest/" 2>/dev/null || true
    return 0
  fi
  warn "Directorio no encontrado: $src (omitido)"; return 0
}

copy_component(){
  local name="$1"
  case "$name" in
    bspwm)
      copy_file_if_exists "$ROOT_DIR/bspwm/bspwmrc" "$CONFIG_DIR/bspwm/bspwmrc" && chmod +x "$CONFIG_DIR/bspwm/bspwmrc";;
    sxhkd)
      copy_file_if_exists "$ROOT_DIR/sxhkd/sxhkdrc" "$CONFIG_DIR/sxhkd/sxhkdrc";;
    polybar)
      copy_file_if_exists "$ROOT_DIR/polybar/current.ini" "$CONFIG_DIR/polybar/config.ini"
      copy_file_if_exists "$ROOT_DIR/polybar/launch.sh" "$CONFIG_DIR/polybar/launch.sh" && chmod +x "$CONFIG_DIR/polybar/launch.sh"
      copy_dir_if_exists "$ROOT_DIR/polybar/scripts" "$CONFIG_DIR/polybar/scripts";;
    picom)
      copy_file_if_exists "$ROOT_DIR/picom/picom.conf" "$CONFIG_DIR/picom/picom.conf";;
    dunst)
      copy_dir_if_exists "$ROOT_DIR/dunst" "$CONFIG_DIR/dunst";;
    kitty)
      copy_file_if_exists "$ROOT_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf";;
    rofi)
      copy_file_if_exists "$ROOT_DIR/rofi/config.rasi" "$CONFIG_DIR/rofi/config.rasi";;
    wallpaper)
      copy_dir_if_exists "$ROOT_DIR/wallpaper" "$CONFIG_DIR/wallpaper";;
    all)
      for c in bspwm sxhkd polybar picom dunst kitty rofi wallpaper; do copy_component "$c"; done;;
    *) err "Componente desconocido: $name"; exit 1;;
  esac
  ok "Actualizado: $name"
}

restart_component(){
  local name="$1"
  case "$name" in
    bspwm)
      command -v bspc >/dev/null 2>&1 && bspc wm -r || warn "bspc no disponible";;
    sxhkd)
      pkill -USR1 -x sxhkd 2>/dev/null || warn "sxhkd no corriendo";;
    polybar)
      pkill -x polybar 2>/dev/null || true
      if [[ -x "$CONFIG_DIR/polybar/launch.sh" ]]; then
        "$CONFIG_DIR/polybar/launch.sh" &
      else
        warn "launch.sh de polybar no encontrado"
      fi;;
    picom)
      pkill -x picom 2>/dev/null || true
      command -v picom >/dev/null 2>&1 && picom --config "$CONFIG_DIR/picom/picom.conf" &;;
    dunst)
      pkill -x dunst 2>/dev/null || true
      command -v dunst >/dev/null 2>&1 && dunst &;;
    rofi)
      : ;; # no daemon
    kitty)
      warn "Reabre Kitty para aplicar cambios";;
    wallpaper)
      if command -v feh >/dev/null 2>&1; then
        for img in "$CONFIG_DIR/wallpaper"/*; do
          [[ -f "$img" ]] || continue
          feh --bg-fill "$img" && break
        done
      fi;;
    all)
      for c in bspwm sxhkd polybar picom dunst; do restart_component "$c"; done;;
  esac
}

if [[ -z "$1" ]]; then
  echo "Uso: $0 <componente|all>"
  echo "Componentes: bspwm sxhkd polybar picom dunst kitty rofi wallpaper"
  exit 1
fi

copy_component "$1"
restart_component "$1"
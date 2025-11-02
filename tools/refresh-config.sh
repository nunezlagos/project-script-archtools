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
    alacritty)
      copy_file_if_exists "$ROOT_DIR/alacritty/alacritty.yml" "$CONFIG_DIR/alacritty/alacritty.yml";;
    wallpaper)
      copy_dir_if_exists "$ROOT_DIR/wallpaper" "$CONFIG_DIR/wallpaper";;
    all)
      for c in bspwm sxhkd polybar picom dunst kitty alacritty wallpaper; do copy_component "$c"; done;;
    *) err "Componente desconocido: $name"; exit 1;;
  esac
  ok "Actualizado: $name"
}

if [[ -z "$1" ]]; then
  echo "Uso: $0 <componente|all>"
  echo "Componentes: bspwm sxhkd polybar picom dunst kitty alacritty wallpaper"
  exit 1
fi

copy_component "$1"
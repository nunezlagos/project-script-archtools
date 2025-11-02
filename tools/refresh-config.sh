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

copy_component(){
  local name="$1"
  case "$name" in
    bspwm)
      mkdir -p "$CONFIG_DIR/bspwm"
      cp "$ROOT_DIR/bspwm/bspwmrc" "$CONFIG_DIR/bspwm/bspwmrc" && chmod +x "$CONFIG_DIR/bspwm/bspwmrc";;
    sxhkd)
      mkdir -p "$CONFIG_DIR/sxhkd"
      cp "$ROOT_DIR/sxhkd/sxhkdrc" "$CONFIG_DIR/sxhkd/sxhkdrc";;
    polybar)
      mkdir -p "$CONFIG_DIR/polybar" "$CONFIG_DIR/polybar/scripts"
      cp "$ROOT_DIR/polybar/current.ini" "$CONFIG_DIR/polybar/config.ini"
      cp "$ROOT_DIR/polybar/launch.sh" "$CONFIG_DIR/polybar/launch.sh" && chmod +x "$CONFIG_DIR/polybar/launch.sh"
      cp -r "$ROOT_DIR/polybar/scripts/"* "$CONFIG_DIR/polybar/scripts/";;
    picom)
      mkdir -p "$CONFIG_DIR/picom"
      cp "$ROOT_DIR/picom/picom.conf" "$CONFIG_DIR/picom/picom.conf";;
    dunst)
      mkdir -p "$CONFIG_DIR/dunst" && cp -r "$ROOT_DIR/dunst/"* "$CONFIG_DIR/dunst/";;
    kitty)
      mkdir -p "$CONFIG_DIR/kitty"
      cp "$ROOT_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf";;
    alacritty)
      mkdir -p "$CONFIG_DIR/alacritty" && cp "$ROOT_DIR/alacritty/alacritty.yml" "$CONFIG_DIR/alacritty/alacritty.yml";;
    wallpaper)
      mkdir -p "$CONFIG_DIR/wallpaper" && cp -r "$ROOT_DIR/wallpaper/"* "$CONFIG_DIR/wallpaper/";;
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
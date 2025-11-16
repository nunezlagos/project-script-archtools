#!/bin/bash
set -euo pipefail

# Polybar setup: install package, deploy configs, optional fonts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

log(){ echo "[polybar] $1"; }
run_quiet(){ "$@" >/dev/null 2>&1 || true; }

require_root(){
  if [[ $EUID -ne 0 ]]; then
    log "Root privileges required (run with sudo)."; exit 1
  fi
}

install_polybar(){
  if command -v pacman >/dev/null 2>&1; then
    log "Installing polybar"
    pacman -S --needed --noconfirm polybar || true
  else
    log "pacman not available; skipping package install"
  fi
}

deploy_polybar_config(){
  local src="$ROOT_DIR/polybar"
  local dest="$CONFIG_DIR/polybar"
  if [[ ! -d "$src" ]]; then
    log "Polybar source not found: $src"; return 0
  fi
  mkdir -p "$dest"
  cp -r "$src"/* "$dest"/ 2>/dev/null || true
  chown -R "$USER_NAME:$USER_NAME" "$dest" 2>/dev/null || true
  chmod +x "$dest/launch.sh" 2>/dev/null || true
  chmod +x "$dest/scripts"/*.sh 2>/dev/null || true
  log "Polybar configs deployed to $dest"
}

install_fonts_if_present(){
  local font_src="$ROOT_DIR/polybar/fonts"
  if [[ -d "$font_src" ]]; then
    local font_dest="$HOME_DIR/.local/share/fonts"
    mkdir -p "$font_dest"
    cp -r "$font_src"/* "$font_dest"/ 2>/dev/null || true
    chown -R "$USER_NAME:$USER_NAME" "$font_dest" 2>/dev/null || true
    run_quiet fc-cache -f
    log "Fonts installed to $font_dest"
  fi
}

main(){
  require_root
  install_polybar
  deploy_polybar_config
  install_fonts_if_present
  log "Polybar setup complete"
}

main "$@"
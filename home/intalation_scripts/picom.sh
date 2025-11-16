#!/bin/bash
set -euo pipefail

# Instala/actualiza exclusivamente Picom jonaburg y despliega la configuración desde home/picom

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"
DEST_DIR="$CONFIG_DIR/picom"

log(){ echo "[picom] $1"; }

remove_stock_picom(){
  if command -v pacman >/dev/null 2>&1; then
    if pacman -Qi picom >/dev/null 2>&1; then
      log "Desinstalando picom estándar"
      pacman -Rns --noconfirm picom || log "No se pudo desinstalar picom estándar (continuo)"
    fi
  fi
}

install_picom(){
  # Solo instalamos el fork con animaciones; sin helper AUR, abortamos con mensaje claro
  if command -v yay >/dev/null 2>&1; then
    log "Instalando picom-jonaburg-git vía yay"
    yay -S --needed --noconfirm picom-jonaburg-git || { log "ERROR: fallo instalando picom-jonaburg-git con yay"; exit 1; }
  elif command -v paru >/dev/null 2>&1; then
    log "Instalando picom-jonaburg-git vía paru"
    paru -S --needed --noconfirm picom-jonaburg-git || { log "ERROR: fallo instalando picom-jonaburg-git con paru"; exit 1; }
  else
    log "ERROR: no se encontró yay/paru. Instale un helper AUR y reintente."
    exit 1
  fi
}

deploy_config(){
  mkdir -p "$DEST_DIR"
  local src="$ROOT_DIR/picom/picom-jonaburg.conf"
  if [[ -f "$src" ]]; then
    log "Usando configuración animada (jonaburg): $src"
    cp -f "$src" "$DEST_DIR/picom.conf"
  else
    log "ERROR: no se encontró $src"
    exit 1
  fi
  chown -R "$USER_NAME:$USER_NAME" "$DEST_DIR" 2>/dev/null || true
}

log "Preparando instalación y configuración de Picom jonaburg"
remove_stock_picom
install_picom
deploy_config
# Verificación estricta de versión
if ! command -v picom >/dev/null 2>&1; then
  log "ERROR: picom no está en PATH tras la instalación"; exit 1
fi
if ! picom --version 2>&1 | grep -qi "jonaburg"; then
  log "ERROR: la versión instalada no es jonaburg"; exit 1
fi
log "Picom (jonaburg) instalado y configurado en $DEST_DIR"
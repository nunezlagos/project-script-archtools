#!/bin/bash
set -euo pipefail

# Instala/actualiza exclusivamente Picom jonaburg desde fuente y despliega la configuración desde home/picom

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"
DEST_DIR="$CONFIG_DIR/picom"

log(){ echo "[picom] $1"; }

install_picom(){
  # Opción B: Compilar manualmente desde el repo jonaburg
  log "Instalando dependencias de compilación (meson, ninja, base-devel, git)"
  if command -v pacman >/dev/null 2>&1; then
    pacman -S --needed --noconfirm meson ninja base-devel git || { log "ERROR: fallo instalando herramientas de compilación"; exit 1; }
  fi
  local build_dir="/tmp/picom-jonaburg-build"
  rm -rf "$build_dir" && mkdir -p "$build_dir"
  chown "$USER_NAME:$USER_NAME" "$build_dir" 2>/dev/null || true
  log "Clonando repositorio jonaburg/picom"
  sudo -u "$USER_NAME" env HOME="$HOME_DIR" bash -lc "cd '$build_dir' && git clone https://github.com/jonaburg/picom.git && cd picom && git submodule update --init --recursive" || { log "ERROR: fallo clonando/submodules"; exit 1; }
  log "Compilando con meson/ninja (release)"
  sudo -u "$USER_NAME" env HOME="$HOME_DIR" bash -lc "cd '$build_dir/picom' && meson --buildtype=release . build && ninja -C build" || { log "ERROR: fallo compilando picom"; exit 1; }
  log "Instalando binario en /usr/local/bin"
  ninja -C "$build_dir/picom/build" install || { log "ERROR: fallo instalando picom en /usr/local"; exit 1; }
  log "Picom instalado en /usr/local/bin/picom"

  # Asegurar que el binario quede visible en PATH del sistema
  if [[ -x "/usr/local/bin/picom" ]]; then
    if ! command -v picom >/dev/null 2>&1; then
      ln -sf "/usr/local/bin/picom" "/usr/bin/picom" && \
        log "Creado symlink /usr/bin/picom -> /usr/local/bin/picom" || \
        log "AVISO: no se pudo crear symlink en /usr/bin; verifique PATH incluye /usr/local/bin"
    fi
  else
    log "ERROR: /usr/local/bin/picom no existe tras la instalación"; exit 1
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
install_picom
deploy_config
# Verificación estricta de versión
if ! command -v picom >/dev/null 2>&1; then
  log "ERROR: picom no está en PATH tras la instalación"; exit 1
fi
version="$(picom --version 2>&1 || true)"
log "Picom versión detectada: ${version}"
log "Picom instalado y configurado en $DEST_DIR"
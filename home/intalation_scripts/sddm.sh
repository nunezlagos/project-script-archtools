#!/bin/bash
set -euo pipefail

# Instalación segura de SDDM y limpieza de otros display managers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF_SRC_DIR="$PROJECT_ROOT/sddm"
THEME_NAME="Archtools-Nordic-X11"
# Fuente del tema desde el repo (no dependemos de inspiration en el sistema destino)
THEME_SRC_DIR="$CONF_SRC_DIR/themes/$THEME_NAME"
THEME_DEST_DIR="/usr/share/sddm/themes/$THEME_NAME"

log(){ echo "[sddm] $1"; }
run_quiet(){ "$@" >/dev/null 2>&1 || true; }

require_root(){
  if [[ $EUID -ne 0 ]]; then
    log "Se requiere ejecutar como root (sudo)."; exit 1
  fi
}

disable_and_remove_others(){
  log "Deshabilitando y deteniendo otros gestores de inicio (GDM/LightDM/LXDM)"
  for svc in gdm lightdm lxdm; do
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
      run_quiet systemctl disable "$svc"
      run_quiet systemctl stop "$svc"
      log "Servicio deshabilitado: $svc"
    fi
  done
  log "Desinstalando paquetes de otros gestores de inicio (si existen)"
  run_quiet pacman -Rns --noconfirm gdm
  run_quiet pacman -Rns --noconfirm lightdm
  run_quiet pacman -Rns --noconfirm lxdm
}

install_sddm(){
  log "Instalando SDDM"
  pacman -S --needed --noconfirm sddm || { log "Fallo instalando sddm"; exit 1; }
}

deploy_theme(){
  if [[ ! -d "$THEME_SRC_DIR" ]]; then
    log "Tema fuente no encontrado: $THEME_SRC_DIR (se omitirá la instalación del tema)"; return 0
  fi
  log "Desplegando tema SDDM '$THEME_NAME' desde $THEME_SRC_DIR"
  mkdir -p "$THEME_DEST_DIR"
  cp -r "$THEME_SRC_DIR"/* "$THEME_DEST_DIR"/
  # Si hay un wallpaper de login en el repo, úsalo como fondo
  if [[ -f "$PROJECT_ROOT/wallpaper/login.png" ]]; then
    mkdir -p "$THEME_DEST_DIR/assets"
    cp "$PROJECT_ROOT/wallpaper/login.png" "$THEME_DEST_DIR/assets/bg.jpg"
  fi
  # Ajustar metadatos para reflejar el fork
  if [[ -f "$THEME_DEST_DIR/metadata.desktop" ]]; then
    run_quiet sed -i "s/^Name=.*/Name=$THEME_NAME/" "$THEME_DEST_DIR/metadata.desktop"
    run_quiet sed -i "s/^Comment=.*/Comment=Fork basado en Nordic-darker, optimizado para Arch+bspwm X11/" "$THEME_DEST_DIR/metadata.desktop"
  fi
  # Permisos seguros
  chown -R root:root "$THEME_DEST_DIR" 2>/dev/null || true
  chmod -R u+rwX,go+rX "$THEME_DEST_DIR" 2>/dev/null || true
  log "Tema copiado a $THEME_DEST_DIR"
}

deploy_config(){
  log "Aplicando configuración de SDDM desde $CONF_SRC_DIR"
  local etc_conf_dir="/etc/sddm.conf.d"
  mkdir -p "$etc_conf_dir"
  if [[ -d "$CONF_SRC_DIR/conf.d" ]]; then
    for f in "$CONF_SRC_DIR/conf.d"/*.conf; do
      [[ -f "$f" ]] || continue
      local dest="$etc_conf_dir/$(basename "$f")"
      cp "$f" "$dest"
      chmod 0644 "$dest"; chown root:root "$dest" 2>/dev/null || true
      log "Config copiada: $dest"
    done
  fi
}

enable_sddm(){
  log "Habilitando SDDM"
  systemctl enable sddm || log "No se pudo habilitar SDDM"
  # Dejar el arranque en target gráfico si corresponde
  systemctl set-default graphical.target >/dev/null 2>&1 || true
}

main(){
  require_root
  disable_and_remove_others
  install_sddm
  deploy_theme
  deploy_config
  enable_sddm
  log "SDDM instalado y configurado"
}

main "$@"
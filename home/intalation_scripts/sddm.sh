#!/bin/bash
set -euo pipefail

# Safe SDDM installation and cleanup of other display managers

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
    log "Root privileges required (run with sudo)."; exit 1
  fi
}

disable_and_remove_others(){
  log "Disabling and stopping other display managers (GDM/LightDM/LXDM)"
  for svc in gdm lightdm lxdm; do
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
      run_quiet systemctl disable "$svc"
      run_quiet systemctl stop "$svc"
      log "Service disabled: $svc"
    fi
  done
  log "Removing other display manager packages (if present)"
  run_quiet pacman -Rns --noconfirm gdm
  run_quiet pacman -Rns --noconfirm lightdm
  run_quiet pacman -Rns --noconfirm lxdm
}

install_sddm(){
  log "Installing SDDM"
  pacman -S --needed --noconfirm sddm || { log "Failed installing sddm"; exit 1; }
}

deploy_theme(){
  if [[ ! -d "$THEME_SRC_DIR" ]]; then
    log "Theme source not found: $THEME_SRC_DIR (skipping theme deployment)"; return 0
  fi
  log "Deploying SDDM theme '$THEME_NAME' from $THEME_SRC_DIR"
  mkdir -p "$THEME_DEST_DIR"
  cp -r "$THEME_SRC_DIR"/* "$THEME_DEST_DIR"/
  # If there is a login wallpaper in the repo, use it as background
  mkdir -p "$THEME_DEST_DIR/assets"
  local login_png="$PROJECT_ROOT/wallpaper/login.png"
  local login_jpg="$PROJECT_ROOT/wallpaper/login.jpg"
  if [[ -f "$login_png" ]]; then
    cp "$login_png" "$THEME_DEST_DIR/assets/bg.png"
    log "Login background applied (PNG)"
  elif [[ -f "$login_jpg" ]]; then
    cp "$login_jpg" "$THEME_DEST_DIR/assets/bg.jpg"
    log "Login background applied (JPG)"
  else
    log "No login wallpaper found (login.png/login.jpg) in $PROJECT_ROOT/wallpaper"
  fi
  # Adjust metadata to reflect the fork
  if [[ -f "$THEME_DEST_DIR/metadata.desktop" ]]; then
    run_quiet sed -i "s/^Name=.*/Name=$THEME_NAME/" "$THEME_DEST_DIR/metadata.desktop"
    run_quiet sed -i "s/^Comment=.*/Comment=Fork based on Nordic-darker, optimized for Arch + bspwm (X11)/" "$THEME_DEST_DIR/metadata.desktop"
  fi
  # Secure permissions
  chown -R root:root "$THEME_DEST_DIR" 2>/dev/null || true
  chmod -R u+rwX,go+rX "$THEME_DEST_DIR" 2>/dev/null || true
  log "Theme copied to $THEME_DEST_DIR"
}

deploy_config(){
  log "Applying SDDM configuration from $CONF_SRC_DIR"
  local etc_conf_dir="/etc/sddm.conf.d"
  mkdir -p "$etc_conf_dir"
  if [[ -d "$CONF_SRC_DIR/conf.d" ]]; then
    for f in "$CONF_SRC_DIR/conf.d"/*.conf; do
      [[ -f "$f" ]] || continue
      local dest="$etc_conf_dir/$(basename "$f")"
      cp "$f" "$dest"
      chmod 0644 "$dest"; chown root:root "$dest" 2>/dev/null || true
      log "Config copied: $dest"
    done
  fi
}

# Ensure main /etc/sddm.conf does not override our theme and X11 settings
enforce_main_conf(){
  local main_conf="/etc/sddm.conf"
  local backup="/etc/sddm.conf.backup-$(date +%Y%m%d_%H%M%S)"
  if [[ -f "$main_conf" ]]; then
    cp "$main_conf" "$backup" 2>/dev/null || true
    log "Backed up existing main config to $backup"
  fi
  cat > "$main_conf" <<EOF
[Theme]
Current=$THEME_NAME

[General]
DisplayServer=x11
DefaultSession=bspwm
EOF
  chmod 0644 "$main_conf"; chown root:root "$main_conf" 2>/dev/null || true
  log "Main config enforced (overdrive): theme=$THEME_NAME, DisplayServer=x11, DefaultSession=bspwm"
}

enable_sddm(){
  log "Enabling SDDM"
  systemctl enable sddm || log "Failed to enable SDDM"
  # Set graphical target by default
  systemctl set-default graphical.target >/dev/null 2>&1 || true
}

main(){
  require_root
  disable_and_remove_others
  install_sddm
  deploy_theme
  deploy_config
  enforce_main_conf
  enable_sddm
  log "SDDM installed and configured"
}

main "$@"
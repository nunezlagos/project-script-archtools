#!/bin/bash
set -euo pipefail
umask 022

# SDDM installer: copia archivos desde home/sddm a rutas del sistema

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"   # .../home
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"    # proyecto raíz
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

# Ensure system absolute paths exist and are writable by root
ensure_system_dirs(){
  log "Ensuring system directories exist (/etc, /etc/sddm.conf.d, /usr/share/sddm/themes, /usr/lib/sddm/sddm.conf.d, /usr/share/xsessions)"
  mkdir -p /etc/sddm.conf.d
  mkdir -p /usr/share/sddm/themes
  mkdir -p /usr/lib/sddm/sddm.conf.d
  mkdir -p /usr/share/xsessions
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
}

install_sddm(){
  log "Installing SDDM"
  if command -v pacman >/dev/null 2>&1; then
    pacman -S --needed --noconfirm sddm || log "Failed installing sddm; continuing"
  else
    log "pacman not available; skipping package install"
  fi
}

# Ensure Qt/QML controls and SVG plugins are present for the greeter
install_sddm_dependencies(){
  log "Installing greeter dependencies (Qt Declarative/Controls, SVG, X11)"
  if command -v pacman >/dev/null 2>&1; then
    pacman -S --needed --noconfirm qt6-declarative qt6-quickcontrols2 qt6-graphicaleffects qt6-svg || true
    pacman -S --needed --noconfirm xorg-server xorg-xauth || true
    if pacman -Si qt5-quickcontrols2 >/dev/null 2>&1; then
      pacman -S --needed --noconfirm qt5-quickcontrols2 qt5-svg || true
    fi
  else
    log "pacman not available; skipping dependency installation"
  fi
}

# Guard to handle pacman lock file if previous run crashed
ensure_pacman_ready(){
  if [[ -f /var/lib/pacman/db.lck ]]; then
    if pgrep -x pacman >/dev/null 2>&1; then
      log "pacman is running; waiting for it to finish..."
      sleep 5
    else
      log "Found stale pacman lock; removing /var/lib/pacman/db.lck"
      rm -f /var/lib/pacman/db.lck
    fi
  fi
}

resolve_wallpaper(){
  local path="$REPO_ROOT/wallpaper/login.png"
  [[ -f "$path" ]] && { echo "$path"; return 0; }
  path="$PROJECT_ROOT/wallpaper/login.png"
  [[ -f "$path" ]] && { echo "$path"; return 0; }
  echo ""; return 1
}

deploy_theme(){
  if [[ ! -d "$THEME_SRC_DIR" ]]; then
    log "Theme source not found: $THEME_SRC_DIR (skipping theme deployment)"; return 0
  fi
  log "Deploying SDDM theme '$THEME_NAME' from $THEME_SRC_DIR"
  mkdir -p "$THEME_DEST_DIR"
  cp -r "$THEME_SRC_DIR"/* "$THEME_DEST_DIR"/
  mkdir -p "$THEME_DEST_DIR/assets"
  local chosen
  chosen="$(resolve_wallpaper)"
  if [[ -n "$chosen" ]]; then
    cp "$chosen" "$THEME_DEST_DIR/assets/login.png"
    log "Login background applied: $(basename "$chosen")"
  fi
  chown -R root:root "$THEME_DEST_DIR" 2>/dev/null || true
  chmod -R u+rwX,go+rX "$THEME_DEST_DIR" 2>/dev/null || true
  log "Theme copied to $THEME_DEST_DIR"
}

# Validate theme files and greeter ability to load them
validate_sddm_theme(){
  local issues=0
  [[ -f "$THEME_DEST_DIR/Main.qml" ]] || { log "Theme Main.qml missing at $THEME_DEST_DIR"; issues=1; }
  if [[ ! -f "$THEME_DEST_DIR/assets/login.png" ]]; then
    log "No se encontró imagen de fondo en $THEME_DEST_DIR/assets (login.png)"; issues=1
  fi
  if ! command -v sddm-greeter >/dev/null 2>&1; then
    log "sddm-greeter not found (package sddm should provide it)"; issues=1
  else
    # Run greeter in test mode to catch QML import errors without starting the DM
    local out="/tmp/sddm-greeter-test.log"
    if ! sddm-greeter --test-mode --theme "$THEME_DEST_DIR" >"$out" 2>&1; then
      # No mostramos logs en pantalla; dejamos constancia mínima
      log "Greeter test failed (see $out)"; issues=1
      # Hint for common missing modules
      if grep -qi "QtGraphicalEffects" "$out"; then log "Hint: install qt6-graphicaleffects"; fi
      if grep -qi "QtQuick.Controls" "$out"; then log "Hint: install qt6-quickcontrols2"; fi
      if grep -qi "module .* not installed" "$out"; then log "Hint: missing Qt module detected (see above)"; fi
    fi
  fi
  return $issues
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
  else
    log "Missing $CONF_SRC_DIR/conf.d; skipping"
  fi
  if [[ -f "$CONF_SRC_DIR/sddm.conf" ]]; then
    local main_conf="/etc/sddm.conf"
    local backup="/etc/sddm.conf.backup-$(date +%Y%m%d_%H%M%S)"
    [[ -f "$main_conf" ]] && { cp "$main_conf" "$backup" 2>/dev/null || true; log "Backed up existing main config to $backup"; }
    cp "$CONF_SRC_DIR/sddm.conf" "$main_conf"
    chmod 0644 "$main_conf"; chown root:root "$main_conf" 2>/dev/null || true
    log "Main config copied: $main_conf"
  else
    log "Missing $CONF_SRC_DIR/sddm.conf; not writing /etc/sddm.conf"
  fi
}

# Remove/disable conflicting confs that override theme or session
sanitize_conflicts(){
  local etc_conf_dir="/etc/sddm.conf.d"
  [[ -d "$etc_conf_dir" ]] || return 0
  for f in "$etc_conf_dir"/*.conf; do
    [[ -f "$f" ]] || continue
    if grep -Eq '^(Current|ThemeDir)=' "$f" || grep -Eq '^(DisplayServer|DefaultSession)=' "$f"; then
      local backup="${f}.backup-$(date +%Y%m%d_%H%M%S)"
      cp "$f" "$backup" 2>/dev/null || true
      mv "$f" "${f}.disabled" 2>/dev/null || true
      log "Disabled conflicting config: $(basename "$f") (backup: $(basename "$backup"))"
    fi
  done
}

# Also neutralize vendor defaults under /usr/lib that override our settings
sanitize_vendor_conflicts(){
  local vendor_dir="/usr/lib/sddm/sddm.conf.d"
  [[ -d "$vendor_dir" ]] || return 0
  for f in "$vendor_dir"/*.conf; do
    [[ -f "$f" ]] || continue
    if grep -Eq '^(Current|ThemeDir)=' "$f" || grep -Eq '^(DisplayServer|DefaultSession)=' "$f"; then
      local backup="${f}.backup-$(date +%Y%m%d_%H%M%S)"
      cp "$f" "$backup" 2>/dev/null || true
      mv "$f" "${f}.disabled" 2>/dev/null || true
      log "Disabled vendor conflicting config: $(basename "$f") (backup: $(basename "$backup"))"
    fi
  done
}

# Ensure main /etc/sddm.conf does not override our theme and X11 settings
enforce_main_conf(){
  # Mantenido para compatibilidad: ahora delega a deploy_config (copia desde repo)
  :
}

enable_sddm(){
  log "Enabling SDDM"
  systemctl enable sddm || log "Failed to enable SDDM"
}

# Ensure XSession entry for bspwm exists so DefaultSession=bspwm is valid
# Eliminado: no se crean archivos de sesión aquí; se asume provisto por paquetes

# Verify that SDDM sees the expected configuration values
verify_applied_config(){
  local dump="/tmp/sddm-config-dump.log"
  if command -v sddm >/dev/null 2>&1; then
    if sddm --dump-config >"$dump" 2>&1; then
      if ! grep -q "^Current=$THEME_NAME" "$dump"; then
        log "Config check: Theme Current not set to $THEME_NAME (see $dump)"
      fi
      if ! grep -q "^DisplayServer=x11" "$dump"; then
        log "Config check: DisplayServer not x11 (see $dump)"
      fi
      if ! grep -q "^DefaultSession=bspwm" "$dump"; then
        log "Config check: DefaultSession not bspwm (see $dump)"
      fi
    else
      log "Unable to dump SDDM config; see $dump"
    fi
  else
    log "sddm command not found; skipping config dump verification"
  fi
}

main(){
  require_root
  ensure_system_dirs
  ensure_pacman_ready
  disable_and_remove_others
  install_sddm
  install_sddm_dependencies
  deploy_theme
  validate_sddm_theme || log "Theme validation warnings"
  deploy_config
  sanitize_conflicts
  sanitize_vendor_conflicts
  # Immediate existence check for hard paths
  if [[ -f "/etc/sddm.conf" ]]; then
    log "Verified: /etc/sddm.conf exists"
  else
    log "ERROR: /etc/sddm.conf not found after enforcement"
  fi
  enable_sddm
  verify_applied_config
  # Reiniciar SDDM para aplicar inmediatamente el tema si se ejecuta desde TTY
  if systemctl list-units --type=service | grep -q '^sddm.service'; then
    log "Restarting SDDM to apply theme"
    systemctl restart sddm >/dev/null 2>&1 || log "Could not restart sddm (may not be active)"
  fi
  log "SDDM installed and configured"
}

main "$@"
#!/bin/bash
set -euo pipefail

# ArchTools - Minimal setup for BSPWM (no Zsh/OMZ, no Neovim, no GPU/VM)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"
BACKUP_DIR="$HOME_DIR/.config_backup_$(date +%Y%m%d_%H%M%S)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok(){ echo -e "${GREEN}[✓]${NC} $1"; }
warn(){ echo -e "${YELLOW}[!]${NC} $1"; }
err(){ echo -e "${RED}[✗]${NC} $1"; }

# Salida minimalista y progreso
QUIET_MODE=1
LOG_FILE="/tmp/archtools-install.log"
TOTAL_STEPS=22
CURRENT_STEP=0
progress_init(){ : > "$LOG_FILE"; CURRENT_STEP=0; }
progress_step(){
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  local blocks=$((pct / 10))
  local bar=""; local i=0
  while [ $i -lt $blocks ]; do bar="${bar}="; i=$((i+1)); done
  while [ $i -lt 10 ]; do bar="${bar}-"; i=$((i+1)); done
  printf "[%s] %3d%% %s\n" "$bar" "$pct" "$1"
}
run_quiet(){ "$@" >>"$LOG_FILE" 2>&1; }

check_internet(){
  if ping -c 1 archlinux.org &>/dev/null; then
    ok "Internet OK"
  else
    err "No internet"; exit 1
  fi
}

# Paquetes requeridos
packages=(
  xorg-server xorg-xinit xorg-xauth
  bspwm sxhkd polybar picom dunst feh kitty fish
  nano rofi pavucontrol firefox
  networkmanager network-manager-applet
  nm-connection-editor
  udisks2 udiskie libnotify gsimplecal flameshot pasystray
  yazi fastfetch yad calcurse papirus-icon-theme
)

install_packages(){
  run_quiet sudo pacman -Syu --noconfirm --noprogressbar --quiet || { err "Failed to update packages"; exit 1; }
  run_quiet sudo pacman -S --needed --noconfirm --noprogressbar --quiet "${packages[@]}" || warn "Some packages were not installed"
  progress_step "Packages installed"
}

# (eliminado) Verificación específica de LightDM


ensure_dirs(){
  mkdir -p "$CONFIG_DIR" && ok "Base directory: $CONFIG_DIR"
  for d in bspwm sxhkd polybar polybar/scripts picom dunst kitty fish wallpaper rofi; do
    mkdir -p "$CONFIG_DIR/$d"
  done
}

ensure_bspwm_session(){
  # .xinitrc / .xsession para startx/DMs que lo respetan
  local xinit="$HOME_DIR/.xinitrc"
  local xsession="$HOME_DIR/.xsession"
  local wrapper="/usr/local/bin/start-bspwm-session"
  # Wrapper con log para atrapar errores de arranque sin agregar dependencias externas
  if [[ ! -f "$wrapper" ]]; then
    sudo tee "$wrapper" >/dev/null <<'EOF'
#!/bin/sh
# start-bspwm-session: env mínimo + log de inicio para BSPWM
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
mkdir -p "$HOME/.cache"
LOGFILE="$HOME/.cache/bspwm-session.log"
echo "[start] $(date) - launching bspwm" >>"$LOGFILE"
echo "PATH=$PATH" >>"$LOGFILE"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" >>"$LOGFILE"
exec /usr/bin/bspwm >>"$LOGFILE" 2>&1
EOF
    sudo chmod +x "$wrapper"
  fi
  for f in "$xinit" "$xsession"; do
    backup_if_exists "$f"
    cat > "$f" <<'EOF'
#!/bin/sh
exec /usr/local/bin/start-bspwm-session
EOF
    chown "$USER_NAME":"$USER_NAME" "$f" 2>/dev/null || true
    chmod +x "$f"
    : # silencioso
  done
  progress_step "BSPWM session configured"
  # Entrada de sesión de XSession (para gestores de inicio que la respeten)
  local desktop="/usr/share/xsessions/bspwm.desktop"
  if [[ ! -f "$desktop" ]]; then
    sudo tee "$desktop" >/dev/null <<'EOF'
[Desktop Entry]
Name=BSPWM
Comment=Binary space partitioning window manager
Exec=/usr/local/bin/start-bspwm-session
TryExec=/usr/local/bin/start-bspwm-session
Type=XSession
EOF
    ok "BSPWM session registered"
  fi
}

# (eliminado) Configuración de LightDM

# Reparar causas típicas del login loop (permisos de Xauthority)
fix_login_loop(){
  local xa="$HOME_DIR/.Xauthority"
  if [[ -e "$xa" ]]; then
    sudo chown "$USER_NAME:$USER_NAME" "$xa" 2>/dev/null || true
    chmod 600 "$xa" 2>/dev/null || true
  fi
  progress_step "Login loop avoided (permissions and session)"
}

backup_if_exists(){
  local path="$1"; [ -e "$path" ] || return 0
  mkdir -p "$BACKUP_DIR"; cp -r "$path" "$BACKUP_DIR/" 2>/dev/null || true
  warn "Backup: $BACKUP_DIR/$(basename "$path")"
}

copy_configs(){
  ok "Copying configurations"
  declare -A MAP=(
    ["$SCRIPT_DIR/bspwm/bspwmrc"]="$CONFIG_DIR/bspwm/bspwmrc"
    ["$SCRIPT_DIR/sxhkd/sxhkdrc"]="$CONFIG_DIR/sxhkd/sxhkdrc"
    ["$SCRIPT_DIR/polybar/current.ini"]="$CONFIG_DIR/polybar/current.ini"
    ["$SCRIPT_DIR/polybar/workspace.ini"]="$CONFIG_DIR/polybar/workspace.ini"
    ["$SCRIPT_DIR/polybar/colors.ini"]="$CONFIG_DIR/polybar/colors.ini"
    ["$SCRIPT_DIR/polybar/launch.sh"]="$CONFIG_DIR/polybar/launch.sh"
    ["$SCRIPT_DIR/polybar/scripts"]="$CONFIG_DIR/polybar/scripts"
    ["$SCRIPT_DIR/picom/picom.conf"]="$CONFIG_DIR/picom/picom.conf"
    ["$SCRIPT_DIR/dunst"]="$CONFIG_DIR/dunst"
    ["$SCRIPT_DIR/kitty/kitty.conf"]="$CONFIG_DIR/kitty/kitty.conf"
    ["$SCRIPT_DIR/kitty/kitty2.conf"]="$CONFIG_DIR/kitty/kitty2.conf"
    ["$SCRIPT_DIR/fish/config.fish"]="$CONFIG_DIR/fish/config.fish"
    ["$SCRIPT_DIR/rofi/config.rasi"]="$CONFIG_DIR/rofi/config.rasi"
    ["$SCRIPT_DIR/wallpaper"]="$CONFIG_DIR/wallpaper"
  )
  for src in "${!MAP[@]}"; do
    dest="${MAP[$src]}"
    backup_if_exists "$dest"
    rm -rf "$dest" 2>/dev/null || true
    if [ -d "$src" ]; then
      mkdir -p "$dest"; cp -r "$src/"* "$dest/" 2>/dev/null || true
    else
      mkdir -p "$(dirname "$dest")"; cp "$src" "$dest" 2>/dev/null || true
    fi
  done
  chmod +x "$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/polybar/launch.sh" 2>/dev/null || true
  # Asegurar permisos de ejecución para scripts usados por Polybar
  chmod +x "$CONFIG_DIR/polybar/scripts"/*.sh 2>/dev/null || true
  progress_step "Configs applied (clean)"
}

configure_gtk_dark(){
  # Force dark theme for GTK apps (GTK3/GTK4)
  mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0"
  cat >"$CONFIG_DIR/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
EOF
  cat >"$CONFIG_DIR/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
EOF
  chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0" 2>/dev/null || true
  progress_step "GTK dark configured"
}

# (eliminado) Configuración del greeter de LightDM

# (eliminado) Reinstalación de LightDM

reinstall_firefox_clean(){
  : # encabezado silencioso
  # Cerrar proceso si está corriendo
  run_quiet pkill -x firefox || true
  sleep 1

  # Desinstalar variantes
  if command -v pacman >/dev/null 2>&1; then
    run_quiet sudo pacman -Rns --noconfirm firefox firefox-esr firefox-developer-edition || true
  fi

  # Limpiar perfiles y cachés del usuario
  run_quiet rm -rf \
    "$HOME_DIR/.mozilla" \
    "$HOME_DIR/.cache/mozilla" \
    "$HOME_DIR/.config/mozilla" 2>/dev/null || true
  # Configuración del sistema
  run_quiet sudo rm -rf /etc/firefox || true

  # Quitar dependencias huérfanas (Arch)
  if command -v pacman >/dev/null 2>&1; then
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [[ -n "${orphans:-}" ]]; then
      run_quiet sudo pacman -Rns --noconfirm $orphans || true
    fi
  fi

  # Reinstalar Firefox estable vía pacman
  if command -v pacman >/dev/null 2>&1; then
    run_quiet sudo pacman -S --noconfirm --noprogressbar --quiet firefox || {
      warn "Could not reinstall Firefox with pacman"
      return 0
    }
    progress_step "Firefox reinstalled"
  else
    warn "Pacman not available; skipping Firefox reinstall"
  fi
}

install_yay(){
  if command -v yay >/dev/null 2>&1; then
    progress_step "yay already installed"
    return 0
  fi
  run_quiet sudo pacman -S --needed --noconfirm --noprogressbar --quiet git base-devel || { err "Failed to install git/base-devel"; return 1; }
  local tmpdir="/tmp/yay_install"
  run_quiet rm -rf "$tmpdir" && mkdir -p "$tmpdir"
  chown "$USER_NAME":"$USER_NAME" "$tmpdir" 2>/dev/null || true
  sudo -u "$USER_NAME" bash -c "cd '$tmpdir' && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm" >>"$LOG_FILE" 2>&1 || { err "Failed installing yay"; return 1; }
  run_quiet rm -rf "$tmpdir" || true
  progress_step "yay installed"
}

disable_conflicting_services(){
  for svc in gdm lightdm lxdm; do
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
      sudo systemctl disable "$svc" >/dev/null 2>&1 || true
      sudo systemctl stop "$svc" >/dev/null 2>&1 || true
      warn "Potentially conflicting service disabled: $svc"
    fi
  done
}

# (eliminado) Habilitación de LightDM

# Asegurar servicios auxiliares del login activos
ensure_login_services(){
  if systemctl list-unit-files | grep -q '^accounts-daemon.service'; then
    sudo systemctl start accounts-daemon >/dev/null 2>&1 || true
  fi
  if systemctl list-unit-files | grep -q '^polkit.service'; then
    sudo systemctl start polkit >/dev/null 2>&1 || true
  fi
  progress_step "Login services started"
}

enable_networkmanager(){
  if systemctl list-unit-files | grep -q '^NetworkManager.service'; then
    sudo systemctl enable NetworkManager >/dev/null 2>&1 || warn "Failed to enable NetworkManager"
    sudo systemctl start NetworkManager >/dev/null 2>&1 || true
    progress_step "NetworkManager enabled"
  else
    warn "NetworkManager not available (package not installed?)"
  fi
}

write_command_list(){
  if [ -f "$SCRIPT_DIR/command-list" ]; then
    sudo cp "$SCRIPT_DIR/command-list" /command-list >/dev/null 2>&1
    cp "$SCRIPT_DIR/command-list" "$HOME_DIR/command-list" >/dev/null 2>&1
  else
    sudo tee /command-list >/dev/null <<'EOF'
# Command List (Kitty quick reference)

## Launchers
- rofi: `rofi -show drun` (apps) | `rofi -show run` (commands)
- terminal: `kitty`
- browser: `firefox`

## System
- audio: `pavucontrol`
- network: `nm-applet` (tray) | `nm-connection-editor`
- devices: `udiskie --tray` | `udisksctl`

## BSPWM / Windows
- restart WM: `bspc wm -r`
- focus move: `bspc node -f {north|south|east|west}`
- move window: `bspc node -v <dx> <dy>`
- toggle state: `bspc node -t {tiled|floating|fullscreen}`

## Bars and notifications
- polybar: `~/.config/polybar/launch.sh`
- compositor: `picom --config ~/.config/picom/picom.conf`
- notifications: `dunst`

## Wallpaper
- `feh --bg-fill ~/.config/wallpaper/<image>`

## Config
- refresh configs: `tools/refresh-config.sh <component|all>`
- typical components: `bspwm sxhkd polybar picom dunst kitty rofi wallpaper`

## Services
- enable network: `sudo systemctl enable NetworkManager && sudo systemctl start NetworkManager`

EOF
    cp /command-list "$HOME_DIR/command-list" 2>/dev/null || true
  fi
  progress_step "Command list written"
}

final_tips(){
  progress_step "Installation complete"
  echo "Detailed log: $LOG_FILE"
}

reboot_system(){
  progress_step "Rebooting system"
  sudo systemctl reboot >/dev/null 2>&1 || systemctl reboot >/dev/null 2>&1 || sudo reboot >/dev/null 2>&1 || reboot >/dev/null 2>&1 || true
}

main(){
  progress_init
  check_internet
  progress_step "Internet OK"
  disable_conflicting_services
  run_quiet sudo pacman -Syu --noconfirm --noprogressbar --quiet || warn "Pre-update with pacman failed"
  progress_step "System updated"
  install_packages
  # (LightDM eliminado)
  install_yay || warn "yay could not be installed"
  ensure_dirs; progress_step "Directories prepared"
  ensure_bspwm_session
  copy_configs
  configure_gtk_dark
  # (LightDM eliminado)
  ensure_login_services
  fix_login_loop
  # Install and enforce SDDM after dotfiles are installed
  SDDM_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/sddm.sh"
  if [[ -f "$SDDM_SCRIPT" ]]; then
    if ! sudo bash "$SDDM_SCRIPT" >>"$LOG_FILE" 2>&1; then
      warn "SDDM reported issues; continuing and logging details."
      echo "----- Last 150 lines from $LOG_FILE -----"
      tail -n 150 "$LOG_FILE" 2>/dev/null || true
      echo "----- Recent SDDM journal -----"
      journalctl -u sddm -n 100 --no-pager 2>/dev/null || true
    fi
    progress_step "SDDM installed"
  else
    warn "SDDM script not found at $SDDM_SCRIPT"
  fi
  reinstall_firefox_clean
  # (LightDM eliminado)
  enable_networkmanager
  sudo chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR" 2>/dev/null || true
  progress_step "Permissions set"
  write_command_list
  run_quiet sudo pacman -Syu --noconfirm --noprogressbar --quiet || warn "Final pacman upgrade failed"
  if command -v yay >/dev/null 2>&1; then
    yay -Syu --noconfirm --cleanafter --noredownload >>"$LOG_FILE" 2>&1 || true
    progress_step "AUR updated"
  fi
  final_tips
  reboot_system
}

main "$@"
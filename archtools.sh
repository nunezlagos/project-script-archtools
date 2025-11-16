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

# Reglas de ejecución (RULES_PROMPT): Arch + TTY + usuario real + continuar en validaciones
enforce_rules_prompt(){
  # 1) Arch Linux (pacman disponible)
  if ! command -v pacman >/dev/null 2>&1; then
    err "Este instalador requiere Arch Linux (pacman no encontrado)"; exit 1
  fi
  # 2) TTY
  if [[ ! -t 1 ]]; then
    warn "Se recomienda ejecutar en TTY (no detección de TTY)"
  fi
  # 3) Usuario real no root
  if [[ "$USER_NAME" == "root" ]]; then
    warn "Se detectó ejecución como root. Recomendado: usar sudo desde un usuario real (ej. jumper)"
  fi
  # 5) Resolución de rutas y destino
  [[ -n "$SCRIPT_DIR" ]] || { err "No se pudo resolver SCRIPT_DIR"; exit 1; }
  [[ -d "$CONFIG_DIR" ]] || mkdir -p "$CONFIG_DIR"
  echo "[rules] RULES_PROMPT_ARCHTOOLS aplicado: Arch+TTY+Usuario real+Continuar en validaciones" >>"$LOG_FILE"
}

# Minimal output and progress
QUIET_MODE=1
LOG_FILE="/tmp/archtools-install.log"
TOTAL_STEPS=27
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

# Fancy progress rendering with status icons
mk_bar(){
  local pct=$1; local blocks=$((pct / 10)); local bar=""; local i=0
  while [ $i -lt $blocks ]; do bar="${bar}█"; i=$((i+1)); done
  while [ $i -lt 10 ]; do bar="${bar}·"; i=$((i+1)); done
  echo "$bar"
}

progress_mark(){
  local status=$1; shift; local msg="$*"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  local bar; bar=$(mk_bar "$pct")
  local icon color
  case "$status" in
    ok)   icon="✓"; color="$GREEN" ;;
    fail) icon="✗"; color="$RED"   ;;
    *)    icon="•";  color="$YELLOW";;
  esac
  printf "[%s] %3d%% %b[%s]%b %s\n" "$bar" "$pct" "$color" "$icon" "$NC" "$msg"
}

# Print details from verification logs when a verify_fn reports failure
print_verify_fail_details(){
  local verify_fn="$1"
  local pattern="[${verify_fn}]"
  echo "[details] Verification failed in ${verify_fn}. Relevant log entries:" 
  if grep -Fq "$pattern" "$LOG_FILE"; then
    grep -F "$pattern" "$LOG_FILE" | tail -n 10
  else
    echo "[details] No explicit entries for ${verify_fn}. Showing last 20 lines of log:"
    tail -n 20 "$LOG_FILE"
  fi
}

# Task runner with post-configuration verification
run_and_verify(){
  local task_name="$1"; local script_path="$2"; local verify_fn="$3"
  if [[ ! -f "$script_path" ]]; then
    warn "$task_name script not found at $script_path"
    progress_mark fail "$task_name"
    return 1
  fi
  if ! sudo bash "$script_path" >>"$LOG_FILE" 2>&1; then
    warn "$task_name reported issues during execution"
    if "$verify_fn" >/dev/null 2>&1; then
      progress_mark ok "$task_name"
      return 0
    else
      progress_mark fail "$task_name"
      print_verify_fail_details "$verify_fn"
      return 1
    fi
  fi
  if "$verify_fn" >/dev/null 2>&1; then
    progress_mark ok "$task_name"
    return 0
  else
    warn "$task_name execution succeeded but verification failed"
    progress_mark fail "$task_name"
    print_verify_fail_details "$verify_fn"
    return 1
  fi
}

# Verifiers for each config task
verify_dirs(){
  [[ -d "$CONFIG_DIR" ]] && \
  [[ -d "$CONFIG_DIR/bspwm" ]] && \
  [[ -d "$CONFIG_DIR/sxhkd" ]] && \
  [[ -d "$CONFIG_DIR/dunst" ]] && \
  [[ -d "$CONFIG_DIR/kitty" ]] && \
  [[ -d "$CONFIG_DIR/fish" ]] && \
  [[ -d "$CONFIG_DIR/rofi" ]] && \
  [[ -d "$CONFIG_DIR/polybar" ]]
}

verify_bspwm(){
  # Requisitos mínimos: config de usuario + wrapper ejecutable
  if [[ ! -f "$CONFIG_DIR/bspwm/bspwmrc" ]]; then
    echo "[verify_bspwm] missing: $CONFIG_DIR/bspwm/bspwmrc" >>"$LOG_FILE"; return 1
  fi
  if [[ ! -x "/usr/local/bin/start-bspwm-session" && ! -x "/usr/bin/start-bspwm-session" ]]; then
    echo "[verify_bspwm] missing exec permission on start-bspwm-session" >>"$LOG_FILE"; return 1
  fi
  # Presencia del binario bspwm
  if ! command -v bspwm >/dev/null 2>&1; then
    echo "[verify_bspwm] bspwm binary not found in PATH" >>"$LOG_FILE"; return 1
  fi
  # Acepta cualquiera: entrada .desktop o archivos de inicio (xinit/xsession)
  if [[ -f "/usr/share/xsessions/bspwm.desktop" || -f "$HOME_DIR/.xinitrc" || -f "$HOME_DIR/.xsession" ]]; then
    return 0
  fi
  echo "[verify_bspwm] missing: /usr/share/xsessions/bspwm.desktop or ~/.xinitrc or ~/.xsession" >>"$LOG_FILE"
  return 1
}

verify_sxhkd(){ [[ -f "$CONFIG_DIR/sxhkd/sxhkdrc" ]]; }
verify_dunst(){ [[ -f "$CONFIG_DIR/dunst/dunstrc" ]]; }
verify_kitty(){ [[ -f "$CONFIG_DIR/kitty/kitty.conf" ]]; }
verify_fish(){ [[ -f "$CONFIG_DIR/fish/config.fish" ]]; }
verify_rofi(){ [[ -f "$CONFIG_DIR/rofi/config.rasi" ]]; }
verify_eww(){ command -v eww >/dev/null 2>&1 && [[ -f "$CONFIG_DIR/eww/eww.yuck" ]]; }
verify_wallpaper(){ [[ -d "$SCRIPT_DIR/wallpaper" ]] && ls -1 "$SCRIPT_DIR/wallpaper"/* >/dev/null 2>&1; }
verify_polybar(){ [[ -f "$CONFIG_DIR/polybar/launch.sh" ]] || [[ -f "$CONFIG_DIR/polybar/current.ini" ]]; }
verify_gtk_dark(){ [[ -f "$HOME_DIR/.config/gtk-3.0/settings.ini" ]] && grep -q "gtk-application-prefer-dark-theme=1" "$HOME_DIR/.config/gtk-3.0/settings.ini"; }
verify_login_services(){ systemctl is-active systemd-logind >/dev/null 2>&1; }
verify_fix_login_loop(){ [[ -f "/usr/share/xsessions/bspwm.desktop" ]] && [[ -x "/usr/local/bin/start-bspwm-session" || -x "/usr/bin/start-bspwm-session" ]]; }
verify_sddm(){ [[ -f "/etc/sddm.conf.d/20-session.conf" ]] || systemctl is-enabled sddm >/dev/null 2>&1; }
verify_networkmanager(){ systemctl is-enabled NetworkManager >/dev/null 2>&1; }
verify_command_list(){ [[ -s "$SCRIPT_DIR/util.txt" ]]; }

check_internet(){
  if ping -c 1 archlinux.org &>/dev/null; then
    ok "Internet OK"
  else
    err "No internet"; exit 1
  fi
}

# Required packages
packages=(
  xorg-server xorg-xinit xorg-xauth
  bspwm sxhkd polybar dunst feh kitty fish
  nano rofi pavucontrol firefox
  networkmanager network-manager-applet
  nm-connection-editor
  udisks2 udiskie libnotify gsimplecal flameshot pasystray
  yazi fastfetch yad calcurse papirus-icon-theme
  bluez bluez-utils blueman
  playerctl
)

install_packages(){
  run_quiet sudo pacman -Syu --noconfirm --noprogressbar --quiet || { err "Failed to update packages"; return 1; }
  run_quiet sudo pacman -S --needed --noconfirm --noprogressbar --quiet "${packages[@]}" || warn "Some packages were not installed"
  return 0
}




reinstall_firefox_clean(){
  :
  # Close Firefox if running
  run_quiet pkill -x firefox || true
  sleep 1

  # Remove Firefox variants
  if command -v pacman >/dev/null 2>&1; then
    run_quiet sudo pacman -Rns --noconfirm firefox firefox-esr firefox-developer-edition || true
  fi

  # Clean user profiles and caches
  run_quiet rm -rf \
    "$HOME_DIR/.mozilla" \
    "$HOME_DIR/.cache/mozilla" \
    "$HOME_DIR/.config/mozilla" 2>/dev/null || true
  # System configuration cleanup
  run_quiet sudo rm -rf /etc/firefox || true

  # Remove orphan dependencies (Arch)
  if command -v pacman >/dev/null 2>&1; then
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [[ -n "${orphans:-}" ]]; then
      run_quiet sudo pacman -Rns --noconfirm $orphans || true
    fi
  fi

  # Reinstall stable Firefox via pacman
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
    return 0
  fi
  run_quiet sudo pacman -S --needed --noconfirm --noprogressbar --quiet git base-devel || { err "Failed to install git/base-devel"; return 1; }
  local tmpdir="/tmp/yay_install"
  run_quiet rm -rf "$tmpdir" && mkdir -p "$tmpdir"
  chown "$USER_NAME":"$USER_NAME" "$tmpdir" 2>/dev/null || true
  sudo -u "$USER_NAME" bash -c "cd '$tmpdir' && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm" >>"$LOG_FILE" 2>&1 || { err "Failed installing yay"; return 1; }
  run_quiet rm -rf "$tmpdir" || true
  return 0
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

## migrated to home/intalation_scripts/config_login_services.sh

## migrated to home/intalation_scripts/config_networkmanager.sh

## migrated to home/intalation_scripts/config_command_list.sh

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
  progress_mark ok "Internet connectivity"
  enforce_rules_prompt
  disable_conflicting_services
  if run_quiet sudo pacman -Syu --noconfirm --noprogressbar --quiet; then
    progress_mark ok "System packages pre-update"
  else
    warn "Pre-update with pacman failed"
    progress_mark fail "System packages pre-update"
  fi
  if install_packages; then
    progress_mark ok "Required packages installed"
  else
    progress_mark fail "Required packages installation"
  fi
  if install_yay; then
    progress_mark ok "yay installed"
  else
    progress_mark fail "yay installation"
  fi
  run_and_verify "Directories prepared" "$SCRIPT_DIR/home/intalation_scripts/config_dirs.sh" verify_dirs || true
  # Configure components using dedicated scripts from home/intalation_scripts
  BSPWM_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_bspwm.sh"
  run_and_verify "BSPWM configured" "$BSPWM_SCRIPT" verify_bspwm || true

  SXHKD_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_sxhkd.sh"
  run_and_verify "SXHKD configured" "$SXHKD_SCRIPT" verify_sxhkd || true

  DUNST_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_dunst.sh"
  run_and_verify "Dunst configured" "$DUNST_SCRIPT" verify_dunst || true

  KITTY_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_kitty.sh"
  run_and_verify "Kitty configured" "$KITTY_SCRIPT" verify_kitty || true

  FISH_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_fish.sh"
  run_and_verify "Fish configured" "$FISH_SCRIPT" verify_fish || true

  ROFI_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_rofi.sh"
  run_and_verify "Rofi configured" "$ROFI_SCRIPT" verify_rofi || true

  WALLPAPER_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_wallpaper.sh"
  run_and_verify "Wallpapers deployed" "$WALLPAPER_SCRIPT" verify_wallpaper || true
  # Configure Polybar via dedicated script (installs package, deploys configs/fonts)
  POLYBAR_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_polybar.sh"
  run_and_verify "Polybar configured" "$POLYBAR_SCRIPT" verify_polybar || true
  EWW_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_eww.sh"
  run_and_verify "Eww installed/configured" "$EWW_SCRIPT" verify_eww || true
  run_and_verify "GTK dark configured" "$SCRIPT_DIR/home/intalation_scripts/config_gtk_dark.sh" verify_gtk_dark || true
  run_and_verify "Login services started" "$SCRIPT_DIR/home/intalation_scripts/config_login_services.sh" verify_login_services || true
  run_and_verify "Login loop avoided" "$SCRIPT_DIR/home/intalation_scripts/config_fix_login_loop.sh" verify_fix_login_loop || true
  # Install and enforce SDDM after dotfiles are installed
  SDDM_SCRIPT="$SCRIPT_DIR/home/intalation_scripts/config_sddm.sh"
  run_and_verify "SDDM installed" "$SDDM_SCRIPT" verify_sddm || true
  reinstall_firefox_clean
  run_and_verify "NetworkManager enabled" "$SCRIPT_DIR/home/intalation_scripts/config_networkmanager.sh" verify_networkmanager || true
  sudo chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR" 2>/dev/null || true
  progress_mark ok "Config ownership set"
  if bash "$SCRIPT_DIR/home/intalation_scripts/config_command_list.sh" >>"$LOG_FILE" 2>&1; then
    if verify_command_list; then progress_mark ok "Command list written"; else progress_mark fail "Command list verification"; fi
  else
    warn "config_command_list reported issues"; progress_mark fail "Command list written"
  fi
  if run_quiet sudo pacman -Syu --noconfirm --noprogressbar --quiet; then
    progress_mark ok "Final system upgrade"
  else
    warn "Final pacman upgrade failed"; progress_mark fail "Final system upgrade"
  fi
  if command -v yay >/dev/null 2>&1; then
    yay -Syu --noconfirm --cleanafter --noredownload >>"$LOG_FILE" 2>&1 && progress_mark ok "AUR packages updated" || progress_mark fail "AUR packages update"
  fi
  final_tips
  reboot_system
}

main "$@"

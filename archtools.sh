#!/bin/bash
set -euo pipefail

# ArchTools - Setup mínimo para BSPWM (sin Zsh/OMZ, sin Neovim, sin GPU/VM)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"
BACKUP_DIR="$HOME_DIR/.config_backup_$(date +%Y%m%d_%H%M%S)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok(){ echo -e "${GREEN}[✓]${NC} $1"; }
warn(){ echo -e "${YELLOW}[!]${NC} $1"; }
err(){ echo -e "${RED}[✗]${NC} $1"; }

check_internet(){
  if ping -c 1 archlinux.org &>/dev/null; then
    ok "Internet OK"
  else
    err "Sin internet"; exit 1
  fi
}

# Paquetes requeridos
packages=(
  xorg-server xorg-xinit
  lightdm lightdm-gtk-greeter
  bspwm sxhkd polybar picom dunst feh kitty
  nano flatpak rofi pavucontrol
  networkmanager network-manager-applet
  udisks2 udiskie
  yazi fastfetch
)

install_packages(){
  sudo pacman -Syu --noconfirm || { err "Fallo al actualizar paquetes"; exit 1; }
  sudo pacman -S --needed --noconfirm "${packages[@]}" || warn "Algún paquete no se instaló"
  ok "Paquetes instalados"
}

install_brave_flatpak(){
  if ! command -v flatpak >/dev/null 2>&1; then
    warn "Flatpak no está disponible, saltando Brave"
    return 0
  fi
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
  if flatpak install -y flathub com.brave.Browser >/dev/null 2>&1; then
    ok "Brave instalado (Flatpak)"
  else
    warn "No se pudo instalar Brave via Flatpak"
  fi
}

create_brave_wrapper(){
  mkdir -p "$HOME_DIR/.local/bin"
  local wrapper_path="$HOME_DIR/.local/bin/brave"
  cat > "$wrapper_path" <<'EOF'
#!/bin/bash
if command -v flatpak >/dev/null 2>&1; then
  exec flatpak run com.brave.Browser "$@"
else
  exec brave "$@"
fi
EOF
  chmod +x "$wrapper_path"
  ok "Wrapper creado: $wrapper_path"
}

ensure_dirs(){
  mkdir -p "$CONFIG_DIR" && ok "Directorio base: $CONFIG_DIR"
  for d in bspwm sxhkd polybar polybar/scripts picom dunst kitty alacritty wallpaper rofi; do
    mkdir -p "$CONFIG_DIR/$d"
  done
}

ensure_bspwm_session(){
  # .xinitrc / .xsession para startx/DMs que lo respetan
  local xinit="$HOME_DIR/.xinitrc"
  local xsession="$HOME_DIR/.xsession"
  for f in "$xinit" "$xsession"; do
    if [[ ! -f "$f" ]]; then
      cat > "$f" <<'EOF'
#!/bin/sh
exec bspwm
EOF
      chown "$USER_NAME":"$USER_NAME" "$f" 2>/dev/null || true
      chmod +x "$f"
      ok "Creado: $f"
    fi
  done
  # Entrada de sesión para LightDM
  local desktop="/usr/share/xsessions/bspwm.desktop"
  if [[ ! -f "$desktop" ]]; then
    sudo tee "$desktop" >/dev/null <<'EOF'
[Desktop Entry]
Name=BSPWM
Comment=Binary space partitioning window manager
Exec=bspwm
TryExec=bspwm
Type=Application
EOF
    ok "Sesión BSPWM registrada en LightDM"
  fi
}

backup_if_exists(){
  local path="$1"; [ -e "$path" ] || return 0
  mkdir -p "$BACKUP_DIR"; cp -r "$path" "$BACKUP_DIR/" 2>/dev/null || true
  warn "Respaldo: $BACKUP_DIR/$(basename "$path")"
}

copy_configs(){
  ok "Copiando configuraciones"
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
    ["$SCRIPT_DIR/alacritty/alacritty.yml"]="$CONFIG_DIR/alacritty/alacritty.yml"
    ["$SCRIPT_DIR/rofi/config.rasi"]="$CONFIG_DIR/rofi/config.rasi"
    ["$SCRIPT_DIR/wallpaper"]="$CONFIG_DIR/wallpaper"
  )
  for src in "${!MAP[@]}"; do
    dest="${MAP[$src]}"
    backup_if_exists "$dest"
    if [ -d "$src" ]; then
      mkdir -p "$dest"; cp -r "$src/"* "$dest/" 2>/dev/null || true
    else
      mkdir -p "$(dirname "$dest")"; cp "$src" "$dest" 2>/dev/null || true
    fi
  done
  chmod +x "$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/polybar/launch.sh" 2>/dev/null || true
  ok "Configuraciones aplicadas"
}

install_yay(){
  if command -v yay >/dev/null 2>&1; then
    ok "yay ya está instalado"
    return 0
  fi
  ok "Instalando yay (AUR helper)"
  sudo pacman -S --needed --noconfirm git base-devel || { err "No se pudo instalar git/base-devel"; return 1; }
  local tmpdir="/tmp/yay_install"
  rm -rf "$tmpdir" && mkdir -p "$tmpdir"
  chown "$USER_NAME":"$USER_NAME" "$tmpdir" 2>/dev/null || true
  sudo -u "$USER_NAME" bash -c "cd '$tmpdir' && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm" || { err "Fallo instalando yay"; return 1; }
  rm -rf "$tmpdir" 2>/dev/null || true
  ok "yay instalado"
}

disable_conflicting_services(){
  for svc in gdm sddm; do
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
      sudo systemctl disable "$svc" >/dev/null 2>&1 || true
      sudo systemctl stop "$svc" >/dev/null 2>&1 || true
      warn "Servicio potencialmente conflictivo deshabilitado: $svc"
    fi
  done
}

enable_lightdm(){
  sudo systemctl enable lightdm >/dev/null 2>&1 || warn "No se pudo habilitar lightdm"
  sudo systemctl restart lightdm >/dev/null 2>&1 || true
  ok "LightDM habilitado"
}

enable_networkmanager(){
  if systemctl list-unit-files | grep -q '^NetworkManager.service'; then
    sudo systemctl enable NetworkManager >/dev/null 2>&1 || warn "No se pudo habilitar NetworkManager"
    sudo systemctl start NetworkManager >/dev/null 2>&1 || true
    ok "NetworkManager habilitado"
  else
    warn "NetworkManager no disponible (paquete no instalado?)"
  fi
}

write_command_list(){
  if [ -f "$SCRIPT_DIR/command-list" ]; then
    sudo cp "$SCRIPT_DIR/command-list" /command-list && ok "Archivo de comandos: /command-list"
    cp "$SCRIPT_DIR/command-list" "$HOME_DIR/command-list" && ok "Copia en home: $HOME_DIR/command-list"
  else
    sudo tee /command-list >/dev/null <<'EOF'
# Command List (resumen para Kitty)

## Lanzadores
- rofi: `rofi -show drun` (apps) | `rofi -show run` (comandos)
- terminal: `kitty`
- navegador: `brave` (wrapper) | `flatpak run com.brave.Browser`

## Gestión del sistema
- audio: `pavucontrol`
- red: `nm-applet` (tray) | `nm-connection-editor`
- dispositivos: `udiskie --tray` | `udisksctl`

## BSPWM / ventanas
- reiniciar WM: `bspc wm -r`
- mover foco: `bspc node -f {north|south|east|west}`
- mover ventana: `bspc node -v <dx> <dy>`
- alternar estado: `bspc node -t {tiled|floating|fullscreen}`

## Barras y notificaciones
- polybar: `~/.config/polybar/launch.sh`
- picom: `picom --config ~/.config/picom/picom.conf`
- dunst: `dunst`

## Fondos de pantalla
- `feh --bg-fill ~/.config/wallpaper/<imagen>`

## Configuración
- refrescar configs: `tools/refresh-config.sh <componente|all>`
- componentes típicos: `bspwm sxhkd polybar picom dunst kitty rofi wallpaper`

## Servicios
- activar display manager: `sudo systemctl enable lightdm && sudo systemctl restart lightdm`
- activar red: `sudo systemctl enable NetworkManager && sudo systemctl start NetworkManager`

EOF
    ok "Archivo de comandos: /command-list"
    cp /command-list "$HOME_DIR/command-list" 2>/dev/null || true
  fi
}

final_tips(){
  echo ""
  ok "Instalación lista"
  echo "- Editor por defecto: nano"
  echo "- Navegador: Brave (Flatpak)"
  echo "- Refrescar configs: tools/refresh-config.sh <componente|all>"
  echo "  Componentes: bspwm sxhkd polybar picom dunst kitty rofi wallpaper"
  echo "- Nota: si Brave no abre con 'brave', usar: flatpak run com.brave.Browser"
  echo "- Wrapper: ~/.local/bin/brave (asegura PATH incluye ~/.local/bin)"
  echo "- Comandos: ver /command-list (bonito para Kitty)"
}

main(){
  check_internet
  disable_conflicting_services
  # Actualización previa completa
  sudo pacman -Syu --noconfirm || warn "Actualización previa con pacman falló"
  install_packages
  install_brave_flatpak
  create_brave_wrapper
  install_yay || warn "yay no se pudo instalar"
  ensure_dirs
  ensure_bspwm_session
  copy_configs
  enable_lightdm
  enable_networkmanager
  sudo chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR" 2>/dev/null || true
  write_command_list
  # Actualización final
  sudo pacman -Syu --noconfirm || warn "Actualización final con pacman falló"
  command -v yay >/dev/null 2>&1 && yay -Syu --noconfirm || true
  final_tips
}

main "$@"
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
  nano flatpak
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
  for d in bspwm sxhkd polybar polybar/scripts picom dunst kitty alacritty wallpaper; do
    mkdir -p "$CONFIG_DIR/$d"
  done
}

backup_if_exists(){
  local path="$1"; [[ -e "$path" ]] || return 0
  mkdir -p "$BACKUP_DIR"; cp -r "$path" "$BACKUP_DIR/" 2>/dev/null || true
  warn "Respaldo: $BACKUP_DIR/$(basename "$path")"
}

copy_configs(){
  ok "Copiando configuraciones"
  declare -A MAP=(
    ["$SCRIPT_DIR/bspwm/bspwmrc"]="$CONFIG_DIR/bspwm/bspwmrc"
    ["$SCRIPT_DIR/sxhkd/sxhkdrc"]="$CONFIG_DIR/sxhkd/sxhkdrc"
    ["$SCRIPT_DIR/polybar/current.ini"]="$CONFIG_DIR/polybar/config.ini"
    ["$SCRIPT_DIR/polybar/launch.sh"]="$CONFIG_DIR/polybar/launch.sh"
    ["$SCRIPT_DIR/polybar/scripts"]="$CONFIG_DIR/polybar/scripts"
    ["$SCRIPT_DIR/picom/picom.conf"]="$CONFIG_DIR/picom/picom.conf"
    ["$SCRIPT_DIR/dunst"]="$CONFIG_DIR/dunst"
    ["$SCRIPT_DIR/kitty/kitty.conf"]="$CONFIG_DIR/kitty/kitty.conf"
    ["$SCRIPT_DIR/alacritty/alacritty.yml"]="$CONFIG_DIR/alacritty/alacritty.yml"
    ["$SCRIPT_DIR/wallpaper"]="$CONFIG_DIR/wallpaper"
  )
  for src in "${!MAP[@]}"; do
    dest="${MAP[$src]}"
    backup_if_exists "$dest"
    if [[ -d "$src" ]]; then
      mkdir -p "$dest"; cp -r "$src/"* "$dest/" 2>/dev/null || true
    else
      mkdir -p "$(dirname "$dest")"; cp "$src" "$dest" 2>/dev/null || true
    fi
  done
  chmod +x "$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/polybar/launch.sh" 2>/dev/null || true
  ok "Configuraciones aplicadas"
}

enable_lightdm(){
  sudo systemctl enable lightdm >/dev/null 2>&1 || warn "No se pudo habilitar lightdm"
  sudo systemctl restart lightdm >/dev/null 2>&1 || true
  ok "LightDM habilitado"
}

final_tips(){
  echo ""
  ok "Instalación lista"
  echo "- Editor por defecto: nano"
  echo "- Navegador: Brave (Flatpak)"
  echo "- Refrescar configs: tools/refresh-config.sh <componente|all>"
  echo "  Componentes: bspwm sxhkd polybar picom dunst kitty alacritty wallpaper"
  echo "- Nota: si Brave no abre con 'brave', usar: flatpak run com.brave.Browser"
  echo "- Wrapper: ~/.local/bin/brave (asegura PATH incluye ~/.local/bin)"
}

main(){
  check_internet
  install_packages
  install_brave_flatpak
  create_brave_wrapper
  ensure_dirs
  copy_configs
  enable_lightdm
  sudo chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR" 2>/dev/null || true
  final_tips
}

main "$@"
#!/bin/bash
set -euo pipefail

# Detecta VirtualBox y configura guest additions en Arch Linux

log(){ echo "[virtualbox] $1"; }
run_quiet(){ "$@" >/dev/null 2>&1 || true; }

if ! command -v systemd-detect-virt >/dev/null 2>&1; then
  log "systemd-detect-virt no disponible; saliendo"
  exit 0
fi

virt=$(systemd-detect-virt || true)
if [[ "$virt" != "oracle" && "$virt" != "vbox" ]]; then
  log "No es VirtualBox ($virt); nada que hacer"
  exit 0
fi

log "Detectado VirtualBox: instalando guest additions"
if command -v pacman >/dev/null 2>&1; then
  pacman -S --needed --noconfirm virtualbox-guest-utils || true
else
  log "pacman no disponible; instala manualmente virtualbox-guest-utils"
fi

# Habilitar servicio
run_quiet systemctl enable vboxservice
run_quiet systemctl start vboxservice

# Cargar módulos en arranque
mkdir -p /etc/modules-load.d
cat >/etc/modules-load.d/virtualbox.conf <<'EOF'
vboxguest
vboxsf
vboxvideo
EOF

# Optimiza resolución automática
mkdir -p /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/20-virtualbox.conf <<'EOF'
Section "Device"
  Identifier  "VirtualBox Graphics"
  Driver      "vboxvideo"
EndSection
EOF

log "Guest additions configuradas. Reinicia para aplicar completamente."
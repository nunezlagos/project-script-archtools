#!/bin/bash
set -euo pipefail

# Detecta VirtualBox y configura guest additions en Arch Linux de forma segura

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

install_guest_additions(){
  if ! command -v pacman >/dev/null 2>&1; then
    log "pacman no disponible; instala manualmente guest additions"
    return 0
  fi
  log "Instalando paquetes de Guest Additions"
  # Preferir módulos precompilados para kernel de Arch
  if pacman -Si virtualbox-guest-modules-arch >/dev/null 2>&1; then
    pacman -S --needed --noconfirm virtualbox-guest-utils virtualbox-guest-modules-arch || true
  else
    # Fallback a DKMS (requiere headers del kernel)
    pacman -S --needed --noconfirm virtualbox-guest-utils virtualbox-guest-dkms linux-headers || true
  fi
}

configure_services(){
  run_quiet systemctl enable vboxservice
  run_quiet systemctl start vboxservice
}

configure_xorg(){
  mkdir -p /etc/X11/xorg.conf.d
  cat >/etc/X11/xorg.conf.d/20-virtualbox.conf <<'EOF'
Section "Device"
  Identifier  "VirtualBox Graphics"
  Driver      "vboxvideo"
EndSection
EOF
}

install_guest_additions
configure_services
configure_xorg

# Regenerar initramfs por si hubo actualización de kernel/módulos
if command -v mkinitcpio >/dev/null 2>&1; then
  run_quiet mkinitcpio -P
fi

log "Guest Additions configuradas. Reinicia para aplicar completamente."
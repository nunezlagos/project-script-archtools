#!/bin/bash

# VirtualBox BSPWM Fix Script
echo "🔧 Configurando Arch Linux para VirtualBox..."

# Detectar si estamos en VirtualBox
if ! lspci | grep -i virtualbox > /dev/null; then
    echo "❌ No se detectó VirtualBox. Este script es solo para VMs de VirtualBox."
    exit 1
fi

echo "✅ VirtualBox detectado. Aplicando configuraciones..."

# 1. Instalar VirtualBox Guest Additions
echo "📦 Instalando VirtualBox Guest Additions..."
sudo pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware

# 2. Habilitar servicios
echo "🔄 Habilitando servicios de VirtualBox..."
sudo systemctl enable vboxservice
sudo systemctl start vboxservice

# 3. Configurar Xorg para VirtualBox
echo "🖥️ Configurando Xorg para VirtualBox..."
sudo mkdir -p /etc/X11/xorg.conf.d/

sudo tee /etc/X11/xorg.conf.d/20-virtualbox.conf << 'EOF'
Section "Device"
    Identifier "VirtualBox Graphics"
    Driver "vboxvideo"
    Option "AccelMethod" "none"
    Option "DRI" "false"
EndSection

Section "Screen"
    Identifier "VirtualBox Screen"
    Device "VirtualBox Graphics"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1024x768" "1280x720" "1366x768" "1920x1080"
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "VirtualBox Layout"
    Screen "VirtualBox Screen"
EndSection
EOF

# 4. Configurar LightDM específicamente para VirtualBox
echo "🔐 Configurando LightDM para VirtualBox..."
sudo tee -a /etc/lightdm/lightdm.conf << 'EOF'

# VirtualBox specific settings
[Seat:*]
xserver-command=X -nolisten tcp -dpi 96
EOF

# 5. Crear .xsession optimizado para VirtualBox
USER_HOME="/home/$USER"
if [[ $EUID -eq 0 && -n "$SUDO_USER" ]]; then
    USER_HOME="/home/$SUDO_USER"
fi

echo "📝 Creando .xsession optimizado para VirtualBox..."
tee "$USER_HOME/.xsession" << 'EOF'
#!/bin/bash

# VirtualBox optimized session
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=bspwm

# Disable compositing for better performance
export PICOM_BACKEND=xrender

# Start VirtualBox services
/usr/bin/VBoxClient --clipboard &
/usr/bin/VBoxClient --draganddrop &
/usr/bin/VBoxClient --display &
/usr/bin/VBoxClient --checkhostversion &
/usr/bin/VBoxClient --seamless &

# Wait a moment for services to start
sleep 2

# Start window manager components
sxhkd &
sleep 1

# Start bspwm
exec bspwm
EOF

chmod +x "$USER_HOME/.xsession"

# 6. Configurar bspwmrc para VirtualBox
echo "🪟 Optimizando bspwmrc para VirtualBox..."
BSPWM_CONFIG="$USER_HOME/.config/bspwm/bspwmrc"
if [[ -f "$BSPWM_CONFIG" ]]; then
    # Añadir configuraciones específicas para VirtualBox
    cat >> "$BSPWM_CONFIG" << 'EOF'

# VirtualBox optimizations
bspc config border_width 1
bspc config window_gap 5
bspc config split_ratio 0.52
bspc config borderless_monocle true
bspc config gapless_monocle true
bspc config focus_follows_pointer false
bspc config pointer_follows_monitor false

# Disable animations for better performance
bspc config presel_feedback true
EOF
fi

# 7. Añadir usuario a grupos necesarios
echo "👤 Configurando permisos de usuario..."
sudo usermod -aG vboxsf,video,audio "$USER"

echo ""
echo "✅ Configuración de VirtualBox completada!"
echo ""
echo "🔄 REINICIA la VM ahora con: sudo reboot"
echo ""
echo "📋 Después del reinicio:"
echo "   1. Deberías ver el login de LightDM"
echo "   2. Si sigue en pantalla negra, presiona Ctrl+Alt+F2"
echo "   3. Ejecuta: startx"
echo ""
echo "⚙️ En la configuración de VirtualBox (VM apagada):"
echo "   - Pantalla → Controlador: VMSVGA"
echo "   - Pantalla → Memoria de video: 128 MB"
echo "   - Pantalla → Aceleración 3D: DESHABILITADA"
echo ""
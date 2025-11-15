#!/bin/bash
set -euo pipefail

USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"

echo "[config_gtk_dark] applying GTK dark settings"
mkdir -p "$HOME_DIR/.config/gtk-3.0" "$HOME_DIR/.config/gtk-4.0"
cat > "$HOME_DIR/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
EOF

cat > "$HOME_DIR/.config/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
EOF

chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR/.config/gtk-3.0" "$HOME_DIR/.config/gtk-4.0" 2>/dev/null || true
echo "[config_gtk_dark] done"
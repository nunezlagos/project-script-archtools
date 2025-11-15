#!/bin/bash
set -euo pipefail

# Instala/actualiza configuración de BSPWM desde home/bspwm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[bspwm] deploying to $CONFIG_DIR/bspwm"
mkdir -p "$CONFIG_DIR/bspwm" "$CONFIG_DIR/bspwm/scripts"
cp -f "$ROOT_DIR/bspwm/bspwmrc" "$CONFIG_DIR/bspwm/bspwmrc"
if [ -d "$ROOT_DIR/bspwm/scripts" ]; then
  cp -rf "$ROOT_DIR/bspwm/scripts/"* "$CONFIG_DIR/bspwm/scripts/" 2>/dev/null || true
fi
chmod +x "$CONFIG_DIR/bspwm/bspwmrc" 2>/dev/null || true
chmod +x "$CONFIG_DIR/bspwm/scripts"/*.sh 2>/dev/null || true
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/bspwm" 2>/dev/null || true

# Registrar sesión BSPWM y wrapper
WRAPPER="/usr/local/bin/start-bspwm-session"
if [[ ! -f "$WRAPPER" ]]; then
  sudo tee "$WRAPPER" >/dev/null <<'EOF'
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
  sudo chmod +x "$WRAPPER"
fi

for f in "$HOME_DIR/.xinitrc" "$HOME_DIR/.xsession"; do
  cat > "$f" <<'EOF'
#!/bin/sh
exec /usr/local/bin/start-bspwm-session
EOF
  chown "$USER_NAME":"$USER_NAME" "$f" 2>/dev/null || true
  chmod +x "$f"
done

DESKTOP_ENTRY="/usr/share/xsessions/bspwm.desktop"
if [[ ! -f "$DESKTOP_ENTRY" ]]; then
  sudo tee "$DESKTOP_ENTRY" >/dev/null <<'EOF'
[Desktop Entry]
Name=BSPWM
Comment=Binary space partitioning window manager
Exec=/usr/local/bin/start-bspwm-session
TryExec=/usr/local/bin/start-bspwm-session
Type=XSession
EOF
fi

echo "[bspwm] done"
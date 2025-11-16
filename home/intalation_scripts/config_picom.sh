#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/picom.sh"
echo "[config_picom] using $TARGET"
if [[ -f "$TARGET" ]]; then
  # Escala a root para permitir instalación de paquetes (pacman/yay/paru)
  if [[ $EUID -ne 0 ]]; then
    echo "[config_picom] escalando a root para instalación y despliegue"
    if command -v sudo >/dev/null 2>&1; then
      exec sudo bash "$TARGET"
    elif command -v doas >/dev/null 2>&1; then
      exec doas bash "$TARGET"
    elif command -v pkexec >/dev/null 2>&1; then
      exec pkexec bash "$TARGET"
    else
      echo "[config_picom] No sudo/doas/pkexec disponible. Ejecute como root: bash $TARGET"; exit 1
    fi
  else
    exec bash "$TARGET"
  fi
else
  echo "[config_picom] missing: $TARGET"; exit 0
fi
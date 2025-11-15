#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/sddm.sh"
echo "[config_sddm] using $TARGET"
if [[ -f "$TARGET" ]]; then
  sudo bash "$TARGET"
else
  echo "[config_sddm] missing: $TARGET"; exit 0
fi
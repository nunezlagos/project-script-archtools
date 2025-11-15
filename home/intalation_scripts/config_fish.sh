#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/fish.sh"
echo "[config_fish] using $TARGET"
if [[ -f "$TARGET" ]]; then
  sudo bash "$TARGET"
else
  echo "[config_fish] missing: $TARGET"; exit 0
fi
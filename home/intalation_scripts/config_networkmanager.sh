#!/bin/bash
set -euo pipefail

echo "[config_networkmanager] enabling and starting NetworkManager"
if systemctl list-unit-files | grep -q '^NetworkManager'; then
  systemctl enable NetworkManager.service || true
  systemctl start NetworkManager.service || true
fi
echo "[config_networkmanager] done"
#!/bin/bash
set -euo pipefail

echo "[config_login_services] starting login-related services if available"
if systemctl list-unit-files | grep -q '^accounts-daemon'; then
  systemctl enable accounts-daemon.service || true
  systemctl start accounts-daemon.service || true
fi

if systemctl list-unit-files | grep -q '^polkit'; then
  systemctl enable polkit.service || true
  systemctl start polkit.service || true
fi
echo "[config_login_services] done"
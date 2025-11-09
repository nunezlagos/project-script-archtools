#!/usr/bin/env bash
set -euo pipefail

# Abrir Firefox en modo privado como ventana flotante nueva únicamente
# Regla temporal por clase de Firefox y eliminación posterior
bspc rule -a Firefox state=floating center=true
firefox --private-window &
sleep 1.5
bspc rule -r Firefox || true
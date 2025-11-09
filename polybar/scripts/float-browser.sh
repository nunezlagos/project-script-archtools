#!/usr/bin/env bash
set -euo pipefail

# Abrir Firefox en modo privado como ventana flotante (sólo la nueva)
# Reglas temporales para clases comunes de Firefox
bspc rule -a firefox -o state=floating center=true
bspc rule -a Navigator -o state=floating center=true
firefox --private-window &
sleep 1.5
bspc rule -r firefox || true
bspc rule -r Navigator || true
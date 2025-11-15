#!/usr/bin/env bash
set -euo pipefail

# Uso: open_float.sh <WM_CLASS> <cmd> [args...]
# Crea una regla temporal de ventana flotante y centrada para la clase indicada
# Lanza el comando y después elimina la regla. Incluye un fallback para flotar
# la ventana enfocada en caso de que la clase no coincida.

cls="${1:-}"
shift || true

if [[ -z "${cls}" || -z "${1:-}" ]]; then
  echo "Uso: open_float.sh <WM_CLASS> <cmd> [args...]" >&2
  exit 1
fi

# Regla temporal específica
bspc rule -a "${cls}" -o state=floating center=true

# Ejecuta el comando solicitado
"$@" &
pid=$!

# Breve espera para permitir que la ventana aparezca y capture la regla
sleep 0.8 || true

# Elimina la regla temporal
bspc rule -r "${cls}" || true

# Fallback: convertir la ventana enfocada en flotante y centrarla
bspc node -t floating 2>/dev/null || true
bspc node -p center 2>/dev/null || true

exit 0
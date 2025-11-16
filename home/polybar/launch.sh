#!/usr/bin/env sh

CONFIG_DIR="$HOME/.config/polybar"
LOG_FILE="$CONFIG_DIR/polybar.log"

# Verify polybar binary
if ! command -v polybar >/dev/null 2>&1; then
  echo "[launch] polybar no está instalado o no está en PATH" >&2
  exit 1
fi

# Verify config files exist
if [ ! -f "$CONFIG_DIR/top_bar.ini" ]; then
  echo "[launch] falta $CONFIG_DIR/top_bar.ini" >&2
  exit 1
fi
if [ ! -f "$CONFIG_DIR/bottom_bar.ini" ]; then
  echo "[launch] falta $CONFIG_DIR/bottom_bar.ini" >&2
  exit 1
fi

# Terminate already running bar instances
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 1; done

# Log detected monitors
polybar -m > "$CONFIG_DIR/monitors.txt" 2>&1 || true

# Start minimal top and bottom bars using separate configs and log output
polybar top -c "$CONFIG_DIR/top_bar.ini" -l info >> "$LOG_FILE" 2>&1 &
polybar bottom -c "$CONFIG_DIR/bottom_bar.ini" -l info >> "$LOG_FILE" 2>&1 &

echo "Polybar (top/bottom) launched; revisa $LOG_FILE"
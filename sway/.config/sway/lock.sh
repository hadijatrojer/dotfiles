#!/usr/bin/env sh
set -e

LOG_FILE=/tmp/sway-lock.log
log() {
  printf '%s %s\n' "$(date -Is)" "$*" >> "$LOG_FILE"
}

LOCK_CONFIG="${HOME}/.config/sway/swaylock.conf"
DPMS_DELAY=10

# Start a temporary swayidle watcher so the display shuts off shortly after locking.
# Commands are wrapped with logging so we can see if they fire.
swayidle -w \
  timeout "${DPMS_DELAY}" "sh -c 'printf \"%s dpms off\\n\" \"\$(date -Is)\" >> ${LOG_FILE}; swaymsg \"output * dpms off\"'" \
  resume "sh -c 'printf \"%s dpms on\\n\" \"\$(date -Is)\" >> ${LOG_FILE}; swaymsg \"output * dpms on\"'" \
  &
idle_pid=$!

cleanup() {
  kill "$idle_pid" 2>/dev/null || true
  swaymsg "output * dpms on"
}
trap cleanup EXIT INT TERM

swaylock --config "${LOCK_CONFIG}"

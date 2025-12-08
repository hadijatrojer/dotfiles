#!/usr/bin/env sh
set -e

LOG_FILE=/tmp/sway-lock.log
PID_FILE=/tmp/sway-lock-idle.pid
LOCK_FILE=/tmp/sway-lock.mutex
log() {
  printf '%s %s\n' "$(date -Is)" "$*" >> "$LOG_FILE"
}

LOCK_CONFIG="${HOME}/.config/sway/swaylock.conf"
DPMS_DELAY=10
INSTANCE_ID="$$"

# Ensure only one lock.sh instance runs at a time to avoid overlapping swaylock/swayidle helpers.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "instance ${INSTANCE_ID}: another lock.sh is running, exiting"
  exit 0
fi
log "instance ${INSTANCE_ID}: acquired lock"

cleanup_stale_idle() {
  log "start cleanup_stale_idle"
  [ -f "$PID_FILE" ] || { log "no pidfile, nothing to clean"; return; }
  old_pid=$(cat "$PID_FILE" 2>/dev/null || true)
  if [ -z "$old_pid" ]; then
    log "pid file exists but empty; removing"
    rm -f "$PID_FILE"
    return
  fi
  if kill -0 "$old_pid" 2>/dev/null; then
    if ps -p "$old_pid" -o comm= 2>/dev/null | grep -q swayidle; then
      log "killing stale swayidle pid=${old_pid}"
      kill "$old_pid" 2>/dev/null || true
      wait "$old_pid" 2>/dev/null || true
    else
      log "pid ${old_pid} alive but not swayidle; leaving alone and removing pidfile"
    fi
  else
    log "pid ${old_pid} not running; removing pidfile"
  fi
  rm -f "$PID_FILE"
}

log "instance ${INSTANCE_ID}: lock.sh start (dpms delay ${DPMS_DELAY}s)"
cleanup_stale_idle
log "cleanup complete"

# Start a temporary swayidle watcher so the display shuts off shortly after locking.
# Commands are wrapped with logging so we can see if they fire.
log "instance ${INSTANCE_ID}: starting swayidle helper"
swayidle -w \
  timeout "${DPMS_DELAY}" "sh -c 'printf \"%s dpms off\\n\" \"\$(date -Is)\" >> ${LOG_FILE}; swaymsg \"output * dpms off\"'" \
  resume "sh -c 'printf \"%s dpms on\\n\" \"\$(date -Is)\" >> ${LOG_FILE}; swaymsg \"output * dpms on\"'" \
  &
idle_pid=$!
echo "$idle_pid" > "$PID_FILE"
log "instance ${INSTANCE_ID}: started swayidle helper pid=${idle_pid}"
kill -0 "$idle_pid" 2>/dev/null || log "warning: swayidle helper pid ${idle_pid} not alive right after start"

cleanup() {
  sig="${1:-EXIT}"
  status=$?
  log "instance ${INSTANCE_ID}: cleanup: sig=${sig} status=${status} killing swayidle pid=${idle_pid}"
  kill "$idle_pid" 2>/dev/null || true
  rm -f "$PID_FILE"
  swaymsg "output * dpms on"
}
trap 'cleanup EXIT' EXIT
trap 'cleanup INT' INT
trap 'cleanup TERM' TERM

log "instance ${INSTANCE_ID}: invoking swaylock"
swaylock --config "${LOCK_CONFIG}"
rc=$?
log "instance ${INSTANCE_ID}: swaylock exited rc=${rc}"
exit "$rc"

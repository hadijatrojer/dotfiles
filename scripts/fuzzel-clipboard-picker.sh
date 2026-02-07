#!/usr/bin/env bash
set -euo pipefail

if ! command -v clipman >/dev/null 2>&1; then
  echo "clipman is not installed" >&2
  exit 1
fi

if ! command -v wl-copy >/dev/null 2>&1; then
  echo "wl-copy is not installed" >&2
  exit 1
fi

picker_cmd='fuzzel --dmenu --prompt "Clipboard " --width 100 --lines 20'

selection="$(clipman pick --tool "${picker_cmd}" 2>/dev/null || true)"
if [ -z "${selection}" ]; then
  # Compatibility fallback for clipman versions using -t.
  selection="$(clipman pick -t "${picker_cmd}" 2>/dev/null || true)"
fi

if [ -z "${selection}" ]; then
  exit 0
fi

printf '%s' "${selection}" | wl-copy

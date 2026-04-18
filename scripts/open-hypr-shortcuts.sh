#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_name="hypr-shortcuts"
plugin_src="${repo_root}/noctalia/.config/noctalia/plugins/${plugin_name}"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia"
plugins_dir="${config_dir}/plugins"
plugin_dst="${plugins_dir}/${plugin_name}"
plugins_file="${config_dir}/plugins.json"

if qs -c noctalia-shell ipc call hyprShortcuts toggle; then
  exit 0
fi

mkdir -p "${plugins_dir}"

if [[ ! -e "${plugin_dst}" ]]; then
  ln -s "${plugin_src}" "${plugin_dst}"
fi

python3 - "${plugins_file}" "${plugin_name}" <<'PY'
import json
import os
import sys

plugins_file, plugin_name = sys.argv[1], sys.argv[2]

data = {
    "version": 2,
    "sources": [
        {
            "enabled": True,
            "name": "Noctalia Plugins",
            "url": "https://github.com/noctalia-dev/noctalia-plugins",
        }
    ],
    "states": {},
}

if os.path.exists(plugins_file):
    with open(plugins_file, encoding="utf-8") as handle:
        try:
            loaded = json.load(handle)
        except json.JSONDecodeError:
            loaded = {}
    if isinstance(loaded, dict):
        data.update({k: loaded[k] for k in ("version", "sources", "states") if k in loaded})

states = data.setdefault("states", {})
state = states.setdefault(
    plugin_name,
    {"enabled": False, "sourceUrl": "https://github.com/noctalia-dev/noctalia-plugins"},
)
state["enabled"] = True
state.setdefault("sourceUrl", "https://github.com/noctalia-dev/noctalia-plugins")

os.makedirs(os.path.dirname(plugins_file), exist_ok=True)
with open(plugins_file, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=4)
    handle.write("\n")
PY

qs -c noctalia-shell kill >/dev/null 2>&1 || true
qs -c noctalia-shell --daemonize >/dev/null 2>&1 &
sleep 1

if qs -c noctalia-shell ipc call hyprShortcuts toggle; then
  exit 0
fi

notify-send \
  "Hypr shortcuts" \
  "Failed to load the Noctalia plugin. Run 'qs -c noctalia-shell kill' and start Noctalia again, then press Super+H."

exit 1

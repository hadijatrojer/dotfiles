#!/usr/bin/env python3
"""Show Hyprland keybindings via fuzzel (or stdout when headless)."""

import json
import os
import re
import subprocess
import sys
from typing import Dict, List, Tuple

MENU_DEFAULT = 'fuzzel --dmenu --prompt "Shortcuts " --width 80'
CONFIG_DEFAULT = os.path.expanduser("~/.config/hypr/hyprland.conf")
STATE_DIR = os.path.expanduser("~/.local/state/fuzzel")
USAGE_FILE = os.path.join(STATE_DIR, "hypr_bindings_usage.json")


def read_config() -> str:
    config_path = os.environ.get("HYPR_CONFIG", CONFIG_DEFAULT)
    try:
        with open(config_path, encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def parse_variables(config_text: str) -> Dict[str, str]:
    variables: Dict[str, str] = {}
    pattern = re.compile(r"^\s*\$([A-Za-z0-9_-]+)\s*=\s*(.+)$")
    for line in config_text.splitlines():
        clean = line.split("#", 1)[0].strip()
        match = pattern.match(clean)
        if match:
            variables[match.group(1)] = match.group(2).strip()
    return variables


def substitute_vars(text: str, variables: Dict[str, str]) -> str:
    return re.sub(r"\$([A-Za-z0-9_-]+)", lambda m: variables.get(m.group(1), m.group(0)), text)


def normalize_combo(mods: str, key: str) -> str:
    tokens = re.split(r"\s+", mods.replace("|", " ").replace("+", " ").strip())
    tokens = [t for t in tokens if t]
    if key.strip():
        tokens.append(key.strip())
    return " + ".join(tokens)


def describe_exec(arg: str) -> str:
    if "fuzzel-emoji-picker.sh" in arg:
        return "Emoji picker"
    if "cheatsheet.py" in arg:
        return "Show Hyprland shortcuts"
    if "$menu" in arg or arg.startswith("fuzzel"):
        return "App launcher"
    if "$terminal" in arg or arg.startswith("ghostty"):
        return "Open terminal"
    if "$fileManager" in arg or arg.startswith("nautilus"):
        return "Open file manager"
    if "playerctl" in arg:
        return "Media control"
    if "wpctl" in arg:
        return "Audio control"
    if "brightnessctl" in arg:
        return "Brightness control"
    if "grim" in arg or "satty" in arg:
        return "Screenshot"
    return "Run command"


def describe_action(action: str, arg: str) -> str:
    action = action.strip().lower()
    arg = arg.strip()
    move_map = {"l": "left", "r": "right", "u": "up", "d": "down"}

    if action == "workspace":
        if re.fullmatch(r"\d+", arg):
            return f"Go to workspace {arg}"
        if arg.startswith("e+"):
            return "Next workspace"
        if arg.startswith("e-"):
            return "Previous workspace"
    if action == "movetoworkspace" and re.fullmatch(r"\d+", arg):
        return f"Send window to workspace {arg}"
    if action == "movefocus":
        return f"Focus {move_map.get(arg.lower(), arg)}".strip()
    if action == "exec":
        return describe_exec(arg)

    action_map = {
        "killactive": "Close window",
        "togglefloating": "Toggle floating",
        "togglesplit": "Toggle split layout",
        "movewindow": "Move window (drag)",
        "resizewindow": "Resize window (drag)",
        "pseudo": "Toggle pseudotile",
        "exit": "Exit Hyprland",
    }
    return action_map.get(action, f"{action} {arg}".strip())


def parse_binds(config_text: str, variables: Dict[str, str]) -> List[Tuple[str, str, str, str]]:
    """Return (combo, action, arg, description) entries from bind/bindd lines."""
    binds: List[Tuple[str, str, str, str]] = []
    pattern = re.compile(r"^\s*(bind\w*)\s*=\s*(.+)$")

    for raw_line in config_text.splitlines():
        clean = raw_line.split("#", 1)[0].strip()
        if not clean:
            continue

        match = pattern.match(clean)
        if not match:
            continue

        bind_kind = match.group(1).lower()
        parts = [substitute_vars(p.strip(), variables) for p in match.group(2).split(",")]
        if len(parts) < 3:
            continue

        if bind_kind.startswith("bindd") and len(parts) >= 4:
            mods, key, desc, action = parts[:4]
            arg = ",".join(parts[4:]).strip()
            description = desc.strip() or describe_action(action, arg)
        else:
            mods, key, action = parts[:3]
            arg = ",".join(parts[3:]).strip()
            description = describe_action(action, arg)

        combo = normalize_combo(mods, key)
        if combo:
            binds.append((combo, action.strip(), arg, description))

    return binds


def load_usage() -> Dict[str, int]:
    try:
        with open(USAGE_FILE, encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, dict):
            return {k: int(v) for k, v in data.items()}
    except Exception:
        pass
    return {}


def save_usage(usage: Dict[str, int]) -> None:
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(USAGE_FILE, "w", encoding="utf-8") as f:
            json.dump(usage, f, indent=2)
    except Exception:
        pass


def render(
    binds: List[Tuple[str, str, str, str]], usage: Dict[str, int]
) -> Tuple[str, Dict[str, Tuple[str, str, str]]]:
    binds_sorted = sorted(
        binds,
        key=lambda b: (-usage.get(b[0], 0), b[0].lower(), b[3].lower()),
    )
    width = max(22, max((len(combo) for combo, _, _, _ in binds_sorted), default=0))

    lines: List[str] = []
    mapping: Dict[str, Tuple[str, str, str]] = {}
    for combo, action, arg, desc in binds_sorted:
        line = f"{combo:<{width}} {desc}"
        lines.append(line)
        mapping[line] = (combo, action, arg)
    return "\n".join(lines), mapping


def main() -> int:
    menu_cmd = os.environ.get("MENU_CMD", MENU_DEFAULT)
    if not (os.environ.get("WAYLAND_DISPLAY") or os.environ.get("DISPLAY")):
        menu_cmd = "cat"

    config_text = read_config()
    if not config_text:
        sys.stderr.write("No bindings available (could not read config).\n")
        return 1

    binds = parse_binds(config_text, parse_variables(config_text))
    if not binds:
        sys.stderr.write("No bindings found in config.\n")
        return 1

    usage = load_usage()
    output, mapping = render(binds, usage)

    if menu_cmd.strip() == "cat":
        print(output)
        return 0

    proc = subprocess.run(menu_cmd, input=output, text=True, shell=True, capture_output=True)
    selection = (proc.stdout or "").strip()
    if not selection:
        return proc.returncode

    entry = mapping.get(selection)
    if not entry:
        return proc.returncode

    combo, action, arg = entry
    usage[combo] = usage.get(combo, 0) + 1
    save_usage(usage)

    dispatch_cmd = ["hyprctl", "dispatch", action]
    if arg:
        dispatch_cmd.append(arg)
    subprocess.run(dispatch_cmd)
    return proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())

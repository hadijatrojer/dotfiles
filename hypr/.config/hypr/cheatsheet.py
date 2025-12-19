#!/usr/bin/env python3
"""Show Hyprland keybindings via wofi (or stdout when headless)."""

import json
import os
import re
import subprocess
import sys
from typing import Dict, List, Tuple

MENU_DEFAULT = 'wofi --dmenu -i -p "Shortcuts"'
CONFIG_DEFAULT = os.path.expanduser("~/.config/hypr/hyprland.conf")
STATE_DIR = os.path.expanduser("~/.local/state/wofi")
USAGE_FILE = os.path.join(STATE_DIR, "hypr_bindings_usage.json")


def read_config() -> str:
    """Read Hyprland config from disk."""
    config_path = os.environ.get("HYPR_CONFIG", CONFIG_DEFAULT)
    try:
        with open(config_path, encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def parse_variables(config_text: str) -> Dict[str, str]:
    """Collect $vars defined in the config for later substitution."""
    variables: Dict[str, str] = {}
    pattern = re.compile(r"^\s*\$([A-Za-z0-9_-]+)\s*=\s*(.+)$")
    for line in config_text.splitlines():
        clean = line.split("#", 1)[0].strip()
        match = pattern.match(clean)
        if match:
            variables[match.group(1)] = match.group(2).strip()
    return variables


def substitute_vars(text: str, variables: Dict[str, str]) -> str:
    def repl(match: re.Match[str]) -> str:
        name = match.group(1)
        return variables.get(name, match.group(0))

    return re.sub(r"\$([A-Za-z0-9_-]+)", repl, text)


def normalize_combo(mods: str, key: str) -> str:
    mods_clean = mods.replace("|", " ").replace("+", " ")
    tokens = [t for t in re.split(r"\s+", mods_clean.strip()) if t]
    key_clean = key.strip()
    if key_clean:
        tokens.append(key_clean)
    return " + ".join(tokens)


def describe_exec(arg: str) -> str:
    if not arg:
        return "Run command"
    if arg.startswith("$menu"):
        return "Application launcher"
    if arg.startswith("wofi"):
        return "Application launcher"
    if arg.startswith("$terminal"):
        return "Terminal"
    if arg.startswith("ghostty"):
        return "Terminal (ghostty)"
    if arg.startswith("$fileManager"):
        return "File manager"
    if arg.startswith("nautilus"):
        return "File manager (Nautilus)"
    if "cheatsheet.sh" in arg:
        return "Show Hyprland shortcuts"

    chrome_profile = re.search(r'--profile-directory="([^"]+)"', arg)
    if (
        "google-chrome" in arg
        or "com.google.Chrome" in arg
        or "--profile-directory=" in arg
    ):
        profile = chrome_profile.group(1) if chrome_profile else "Default"
        friendly = {
            "Profile 1": "Chrome – Hadija@t-scan",
            "Profile 3": "Chrome – Customer support",
            "Profile 4": "Chrome – Calibration",
            "Profile 5": "Chrome – IOQ",
            "Default": "Chrome – Hadija@gmail",
        }.get(profile)
        return friendly or f"Chrome ({profile})"

    if arg.startswith("grim "):
        return "Screenshot selection to Pictures/Screenshots"
    if "wpctl set-volume" in arg:
        if "%+" in arg:
            return "Volume up"
        if "%-" in arg:
            return "Volume down"
        return "Adjust volume"
    if "wpctl set-mute" in arg:
        if "SOURCE" in arg:
            return "Toggle mic mute"
        return "Toggle audio mute"
    if arg.startswith("brightnessctl"):
        if "+" in arg:
            return "Brightness up"
        if "-" in arg:
            return "Brightness down"
        return "Adjust brightness"
    if arg.startswith("playerctl"):
        if "next" in arg:
            return "Next track"
        if "previous" in arg:
            return "Previous track"
        return "Play/pause"
    return arg


def describe(action: str, arg: str) -> str:
    action_lower = action.lower()
    arg_clean = arg.strip()

    if action_lower == "workspace":
        if re.fullmatch(r"\d+", arg_clean):
            return f"Switch to workspace {arg_clean}"
        if arg_clean.startswith("special:"):
            return f"Switch to special workspace {arg_clean.split(':', 1)[1]}"
        if arg_clean.startswith("e+"):
            return "Next workspace"
        if arg_clean.startswith("e-"):
            return "Previous workspace"

    if action_lower == "movetoworkspace":
        if re.fullmatch(r"\d+", arg_clean):
            return f"Move window to workspace {arg_clean}"
        if arg_clean.startswith("special:"):
            return f"Move window to special workspace {arg_clean.split(':', 1)[1]}"

    if action_lower == "togglespecialworkspace":
        name = arg_clean.split(":", 1)[-1] if arg_clean else ""
        return f"Toggle special workspace {name}".strip()

    if action_lower == "killactive":
        return "Close window"
    if action_lower == "exit":
        return "Exit Hyprland"
    if action_lower == "togglefloating":
        return "Toggle floating"
    if action_lower == "pseudo":
        return "Toggle pseudotile"
    if action_lower == "togglesplit":
        return "Toggle split layout"

    if action_lower == "movefocus":
        direction = {"l": "left", "r": "right", "u": "up", "d": "down"}.get(
            arg_clean.lower(), arg_clean
        )
        return f"Focus {direction}".strip()

    if action_lower == "movewindow":
        direction = {"l": "left", "r": "right", "u": "up", "d": "down"}.get(
            arg_clean.lower(), arg_clean
        )
        if direction:
            return f"Move window {direction}".strip()
        return "Move window (drag)"

    if action_lower in {"movewindowpixel", "resizeactive"}:
        return f"{action} {arg_clean}".strip()

    if action_lower == "resizewindow":
        return f"Resize window {arg_clean}".strip() if arg_clean else "Resize window (drag)"

    if action_lower == "exec":
        return describe_exec(arg_clean)

    return f"{action} {arg_clean}".strip()


def parse_binds(
    config_text: str, variables: Dict[str, str]
) -> List[Tuple[str, str, str, str]]:
    """Extract (combo, action, arg, description) entries."""
    binds: List[Tuple[str, str, str, str]] = []
    pattern = re.compile(r"^\s*(bind\w*)\s*=\s*(.+)$")

    for raw_line in config_text.splitlines():
        clean = raw_line.split("#", 1)[0].strip()
        if not clean:
            continue

        match = pattern.match(clean)
        if not match:
            continue

        payload = match.group(2)
        parts = [p.strip() for p in payload.split(",", 3)]
        if len(parts) < 3:
            continue

        mods, key, action = (substitute_vars(p, variables) for p in parts[:3])
        arg = substitute_vars(parts[3], variables) if len(parts) == 4 else ""

        combo = normalize_combo(mods, key)
        if not combo:
            continue

        desc = describe(action, arg)
        binds.append((combo, action, arg, desc))

    return binds


def render(
    binds: List[Tuple[str, str, str, str]], usage: Dict[str, int]
) -> Tuple[str, Dict[str, Tuple[str, str, str]]]:
    # Sort by usage desc, then combo, then description.
    binds_sorted = sorted(
        binds,
        key=lambda entry: (-usage.get(entry[0], 0), entry[0].lower(), entry[3].lower()),
    )

    width = max(22, max((len(combo) for combo, _, _, _ in binds_sorted), default=0))
    lines: List[str] = []
    mapping: Dict[str, Tuple[str, str, str]] = {}

    for combo, action, arg, desc in binds_sorted:
        line = f"{combo:<{width}} {desc}"
        lines.append(line)
        mapping[line] = (combo, action, arg)

    return "\n".join(lines), mapping


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


def main() -> int:
    menu_cmd = os.environ.get("MENU_CMD", MENU_DEFAULT)
    if not (os.environ.get("WAYLAND_DISPLAY") or os.environ.get("DISPLAY")):
        menu_cmd = "cat"

    config_text = read_config()
    if not config_text:
        sys.stderr.write("No bindings available (could not read config).\n")
        return 1

    variables = parse_variables(config_text)
    binds = parse_binds(config_text, variables)
    if not binds:
        sys.stderr.write("No bindings found in config.\n")
        return 1

    usage = load_usage()
    output, mapping = render(binds, usage)
    if menu_cmd.strip() == "cat":
        print(output)
        return 0

    proc = subprocess.run(
        menu_cmd, input=output, text=True, shell=True, capture_output=True
    )
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

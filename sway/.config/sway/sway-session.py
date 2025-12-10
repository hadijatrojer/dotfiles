#!/usr/bin/env python3
"""
Save and restore a Sway session (tiling windows only).

Usage:
  python sway-session.py save [--file PATH]
  python sway-session.py restore [--file PATH]

The saved state stores workspaces, outputs, and the command line for each
window (best effort). On restore the script recreates workspaces, moves them to
their recorded outputs, and re-launches each command.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import time
from pathlib import Path
from typing import List, Optional


DEFAULT_STATE_PATH = Path.home() / ".cache" / "sway-session.json"


def swaymsg_json(message_type: str) -> dict:
    """Run `swaymsg -t <type>` and return JSON output."""
    result = subprocess.check_output(["swaymsg", "-t", message_type], text=True)
    return json.loads(result)


def swaymsg_cmd(command: str) -> None:
    """Send a command string to swaymsg."""
    subprocess.check_call(["swaymsg", command])


def read_cmdline(pid: int) -> Optional[str]:
    """Best-effort read of a process command line."""
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as fh:
            content = fh.read().split(b"\0")
            parts = [p.decode("utf-8", errors="replace") for p in content if p]
            return " ".join(parts) if parts else None
    except FileNotFoundError:
        return None
    except OSError:
        return None


def collect_windows(tree: dict) -> List[dict]:
    """Traverse sway tree and collect window metadata (tiling only)."""
    windows: List[dict] = []

    def _walk(node: dict, output: Optional[str], workspace: Optional[str]) -> None:
        node_type = node.get("type")
        current_output = output
        current_workspace = workspace

        if node_type == "output":
            current_output = node.get("name")
        elif node_type == "workspace":
            current_workspace = node.get("name")

        if node.get("pid") and node_type == "con":
            window_props = node.get("window_properties") or {}
            windows.append(
                {
                    "workspace": current_workspace,
                    "output": current_output,
                    "pid": node.get("pid"),
                    "app_id": node.get("app_id"),
                    "wm_class": window_props.get("class"),
                    "title": node.get("name"),
                    "cmd": read_cmdline(node.get("pid")),
                    "marks": node.get("marks") or [],
                }
            )

        for child in node.get("nodes", []):
            _walk(child, current_output, current_workspace)

    _walk(tree, output=None, workspace=None)
    return windows


def save_state(path: Path) -> None:
    """Capture current sway session to disk."""
    tree = swaymsg_json("get_tree")
    workspaces = swaymsg_json("get_workspaces")
    windows = collect_windows(tree)

    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "saved_at": time.time(),
        "workspaces": [
            {"name": ws.get("name"), "output": ws.get("output"), "focused": ws.get("focused")}
            for ws in workspaces
        ],
        "windows": windows,
    }
    path.write_text(json.dumps(payload, indent=2))
    print(f"Saved session to {path}")


def restore_state(path: Path) -> None:
    """Restore a sway session from disk."""
    if not path.exists():
        raise SystemExit(f"State file not found: {path}")

    data = json.loads(path.read_text())
    workspace_targets = {ws["name"]: ws.get("output") for ws in data.get("workspaces", []) if ws.get("name")}

    # Recreate workspaces on the recorded outputs.
    available_outputs = {out.get("name") for out in swaymsg_json("get_outputs")}
    for ws_name, output in workspace_targets.items():
        if output and output not in available_outputs:
            print(f"Skipping workspace {ws_name}: output {output} not present")
            continue
        swaymsg_cmd(f'workspace "{ws_name}"')
        if output:
            swaymsg_cmd(f'move workspace to output "{output}"')

    windows = data.get("windows", [])
    # Launch applications.
    for win in windows:
        cmd = win.get("cmd")
        ws = win.get("workspace")
        if not cmd or not ws:
            continue
        swaymsg_cmd(f'workspace "{ws}"')
        swaymsg_cmd(f'exec -- {cmd}')

    print(f"Restored session from {path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Save and restore Sway sessions.")
    sub = parser.add_subparsers(dest="command", required=True)

    save_p = sub.add_parser("save", help="Save the current session.")
    save_p.add_argument("--file", type=Path, default=DEFAULT_STATE_PATH, help="Path to save session JSON.")

    restore_p = sub.add_parser("restore", help="Restore a saved session.")
    restore_p.add_argument("--file", type=Path, default=DEFAULT_STATE_PATH, help="Path to load session JSON.")

    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.command == "save":
        save_state(args.file)
    elif args.command == "restore":
        restore_state(args.file)


if __name__ == "__main__":
    main()

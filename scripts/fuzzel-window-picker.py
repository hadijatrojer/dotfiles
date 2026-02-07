#!/usr/bin/env python3
"""Pick and focus a Hyprland window via fuzzel."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from dataclasses import dataclass


MENU_CMD_DEFAULT = 'fuzzel --dmenu --prompt "Window " --width 100 --lines 20'


@dataclass(frozen=True)
class Client:
    address: str
    workspace_id: int
    workspace_name: str
    cls: str
    title: str

    @property
    def label(self) -> str:
        ws = self.workspace_name or str(self.workspace_id)
        return f"[{ws}] {self.cls}  -  {self.title}"


def run(cmd: list[str], *, input_text: str | None = None, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        input=input_text,
        text=True,
        capture_output=True,
        check=check,
    )


def load_clients() -> list[Client]:
    proc = run(["hyprctl", "-j", "clients"])
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "Failed to query Hyprland clients.")

    raw = json.loads(proc.stdout)
    clients: list[Client] = []
    for c in raw:
        address = str(c.get("address", "")).strip()
        if not address:
            continue
        ws = c.get("workspace") or {}
        ws_id = int(ws.get("id", -1))
        ws_name = str(ws.get("name", "")).strip()
        cls = str(c.get("class", "")).strip() or "<unknown>"
        title = str(c.get("title", "")).strip() or "<untitled>"
        clients.append(Client(address=address, workspace_id=ws_id, workspace_name=ws_name, cls=cls, title=title))

    # Keep deterministic ordering.
    clients.sort(key=lambda c: (c.workspace_id, c.cls.lower(), c.title.lower()))
    return clients


def pick_client(clients: list[Client]) -> Client | None:
    if not clients:
        return None

    menu_cmd = os.environ.get("MENU_CMD", MENU_CMD_DEFAULT).strip()
    if not menu_cmd:
        menu_cmd = MENU_CMD_DEFAULT

    labels = [c.label for c in clients]
    proc = subprocess.run(
        menu_cmd,
        input="\n".join(labels),
        text=True,
        shell=True,
        capture_output=True,
    )
    selected = (proc.stdout or "").strip()
    if not selected:
        return None

    for c in clients:
        if c.label == selected:
            return c
    return None


def focus_client(client: Client) -> int:
    # Hyprland primitive: dispatch focuswindow with address selector.
    addr_selector = f"address:{client.address}"
    first = run(["hyprctl", "dispatch", "focuswindow", addr_selector])
    if first.returncode == 0:
        return 0

    # Fallback: switch workspace then retry focus.
    ws_target = client.workspace_name or str(client.workspace_id)
    run(["hyprctl", "dispatch", "workspace", ws_target])
    second = run(["hyprctl", "dispatch", "focuswindow", addr_selector])
    return second.returncode


def main() -> int:
    try:
        clients = load_clients()
    except Exception as exc:
        sys.stderr.write(f"{exc}\n")
        return 1

    if not clients:
        sys.stderr.write("No windows available.\n")
        return 1

    selected = pick_client(clients)
    if selected is None:
        return 0

    return focus_client(selected)


if __name__ == "__main__":
    raise SystemExit(main())

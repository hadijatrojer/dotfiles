#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import platform
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent


@dataclass(frozen=True)
class Package:
    name: str
    stow_dir: Path


COMMON_PACKAGES = [
    Package("btop", REPO_ROOT),
    Package("foot", REPO_ROOT),
    Package("scripts", REPO_ROOT),
    Package("sway", REPO_ROOT),
    Package("vscode", REPO_ROOT),
    Package("zsh", REPO_ROOT),
]

FEDORA_PACKAGES = [
    Package("containers", REPO_ROOT),
    Package("dms", REPO_ROOT),
    Package("systemd", REPO_ROOT),
]

ZSH_PLUGINS_DEST = Path(".local/share/zsh-plugins")
ZSH_PLUGINS = [
    (
        "zsh-autosuggestions",
        "https://github.com/zsh-users/zsh-autosuggestions",
        "v0.7.1",
    ),
    (
        "zsh-syntax-highlighting",
        "https://github.com/zsh-users/zsh-syntax-highlighting",
        "0.8.0",
    ),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Preview or apply the dotfile packages relevant to this host."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--check",
        dest="apply",
        action="store_false",
        help="Preview stow changes without modifying the target (default).",
    )
    mode.add_argument(
        "--apply",
        dest="apply",
        action="store_true",
        help="Apply the selected packages with GNU Stow.",
    )
    parser.set_defaults(apply=False)
    parser.add_argument(
        "--target",
        default=str(Path.home()),
        help="Target directory for GNU Stow. Default: %(default)s",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print the exact stow commands before running them.",
    )
    return parser.parse_args()


def is_fedora() -> bool:
    os_release = Path("/etc/os-release")
    if not os_release.exists():
        return False

    text = os_release.read_text(encoding="utf-8", errors="ignore").lower()
    return "id=fedora" in text or "id_like=fedora" in text


def selected_packages() -> list[Package]:
    packages = list(COMMON_PACKAGES)

    if platform.system().lower() == "linux" and is_fedora():
        packages.extend(FEDORA_PACKAGES)

    return packages


def run_stow(package: Package, target: str, apply: bool, verbose: bool) -> int:
    command = ["stow", "-d", str(package.stow_dir), "-t", target]
    command.append("-v" if apply else "-nv")
    command.append(package.name)

    if verbose:
        print("+", " ".join(command))

    result = subprocess.run(command, cwd=REPO_ROOT, check=False)
    return result.returncode


def run_git(command: list[str], verbose: bool) -> subprocess.CompletedProcess[str]:
    if verbose:
        print("+", " ".join(command))

    return subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def clone_or_update_plugin(
    name: str,
    url: str,
    ref: str,
    dest: Path,
    verbose: bool,
) -> int:
    if not dest.exists():
        result = run_git(["git", "clone", "--quiet", url, str(dest)], verbose)
        if result.returncode != 0:
            print(f"Failed to clone {name}: {result.stderr}", file=sys.stderr)
            return result.returncode

    fetch = run_git(
        ["git", "-C", str(dest), "fetch", "--quiet", "--tags", "origin"],
        verbose,
    )
    if fetch.returncode != 0:
        print(f"Failed to fetch {name}: {fetch.stderr}", file=sys.stderr)
        return fetch.returncode

    checkout = run_git(["git", "-C", str(dest), "checkout", "--quiet", ref], verbose)
    if checkout.returncode != 0:
        print(f"Failed to pin {name} to {ref}: {checkout.stderr}", file=sys.stderr)
        return checkout.returncode

    print(f"PINNED: {name} @ {ref}")
    return 0


def run_zsh_plugins(target: str, apply: bool, verbose: bool) -> int:
    plugins_dir = Path(target) / ZSH_PLUGINS_DEST

    print("\n[zsh-plugins]")
    if not apply:
        for name, _url, ref in ZSH_PLUGINS:
            print(f"Would pin {name} @ {ref}")
        return 0

    plugins_dir.mkdir(parents=True, exist_ok=True)

    failures = 0
    for name, url, ref in ZSH_PLUGINS:
        failures += clone_or_update_plugin(name, url, ref, plugins_dir / name, verbose)
    return failures


def main() -> int:
    args = parse_args()
    target = os.path.abspath(os.path.expanduser(args.target))
    Path(target).mkdir(parents=True, exist_ok=True)
    packages = selected_packages()

    action = "Applying" if args.apply else "Checking"
    print(f"{action} packages into {target}", flush=True)

    failures = 0
    for package in packages:
        print(f"\n[{package.name}]", flush=True)
        failures += run_stow(package, target, args.apply, args.verbose)

    failures += run_zsh_plugins(target, args.apply, args.verbose)

    if failures:
        print(f"\nCompleted with {failures} failing stow command(s).", file=sys.stderr)
        return 1

    print("\nAll selected packages completed successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

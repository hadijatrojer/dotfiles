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
    Package("pi", REPO_ROOT),
    Package("scripts", REPO_ROOT),
    Package("skills", REPO_ROOT),
    Package("sway", REPO_ROOT),
    Package("vscode", REPO_ROOT),
    Package("zsh", REPO_ROOT),
]

FEDORA_PACKAGES = [
    Package("containers", REPO_ROOT),
    Package("dms", REPO_ROOT),
    Package("nautilus", REPO_ROOT),
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

CHATGPT_REPO = Path("/etc/yum.repos.d/chatgpt.repo")
CHATGPT_KEY = Path("/etc/pki/rpm-gpg/RPM-GPG-KEY-chatgpt")
CHATGPT_REPO_URL = "https://persistent.oaistatic.com/codex-app-prod/linux/rpm/$basearch"
CHATGPT_BOOTSTRAP_URL = (
    "https://persistent.oaistatic.com/"
    "codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check, apply, or update the dotfiles relevant to this host."
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
    mode.add_argument(
        "--update",
        action="store_true",
        help="Apply dotfiles and plugins, then update the Fedora Atomic deployment.",
    )
    parser.set_defaults(apply=False, update=False)
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


def run_system_update(verbose: bool) -> int:
    if platform.system().lower() != "linux" or not is_fedora():
        print("\n[system-update]\nSkipped: this is not a Fedora Linux host.")
        return 0

    if not Path("/usr/bin/rpm-ostree").exists():
        print("\n[system-update]\nSkipped: rpm-ostree is not installed.")
        return 0

    command = ["sudo", "rpm-ostree", "upgrade"]
    if verbose:
        print("+", " ".join(command))

    print("\n[system-update]", flush=True)
    return subprocess.run(command, cwd=REPO_ROOT, check=False).returncode


def check_chatgpt() -> int:
    if platform.system().lower() != "linux" or not is_fedora():
        return 0

    if not Path("/usr/bin/rpm-ostree").exists():
        return 0

    print("\n[chatgpt]")
    errors = []

    if not CHATGPT_REPO.exists():
        errors.append(f"missing repository: {CHATGPT_REPO}")
    else:
        repo = CHATGPT_REPO.read_text(encoding="utf-8", errors="ignore")
        expected_lines = {
            "[openai-chatgpt]",
            f"baseurl={CHATGPT_REPO_URL}",
            "enabled=1",
            "gpgcheck=1",
            "repo_gpgcheck=1",
            f"gpgkey=file://{CHATGPT_KEY}",
        }
        for line in sorted(expected_lines):
            if line not in repo.splitlines():
                errors.append(f"unexpected repository config: missing {line}")

    if not CHATGPT_KEY.is_file():
        errors.append(f"missing signing key: {CHATGPT_KEY}")

    package = subprocess.run(
        ["rpm", "-q", "chatgpt"],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    package_installed = package.returncode == 0
    if not package_installed:
        errors.append("chatgpt package is not installed")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        bootstrap_command = "sudo rpm-ostree install "
        if package_installed:
            bootstrap_command += "--uninstall=chatgpt "
        bootstrap_command += CHATGPT_BOOTSTRAP_URL
        print(
            "\nOpenAI creates the repository file and signing key from its "
            "signed RPM.\n"
            "Bootstrap or repair them with:\n\n"
            f"  {bootstrap_command}\n\n"
            "Then reboot and run ./stow-all.py --check again.",
            file=sys.stderr,
        )
        return len(errors)

    print(f"OK: {package.stdout.strip()} from openai-chatgpt")
    return 0


def main() -> int:
    args = parse_args()
    apply = args.apply or args.update
    target = os.path.abspath(os.path.expanduser(args.target))
    Path(target).mkdir(parents=True, exist_ok=True)
    packages = selected_packages()

    action = "Updating" if args.update else "Applying" if apply else "Checking"
    print(f"{action} packages into {target}", flush=True)

    failures = 0
    for package in packages:
        print(f"\n[{package.name}]", flush=True)
        failures += run_stow(package, target, apply, args.verbose)

    failures += run_zsh_plugins(target, apply, args.verbose)
    failures += check_chatgpt()

    if not failures and args.update:
        failures += run_system_update(args.verbose)

    if failures:
        print(f"\nCompleted with {failures} failed check(s).", file=sys.stderr)
        return 1

    print("\nAll selected packages completed successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/cosmic-packages.sh"

rpm-ostree install "${cosmic_packages[@]}"

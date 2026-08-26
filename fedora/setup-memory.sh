#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

sudo install -D -m 0644 \
  "${script_dir}/etc/systemd/zram-generator.conf" \
  /etc/systemd/zram-generator.conf
sudo install -D -m 0644 \
  "${script_dir}/etc/sysctl.d/99-zram.conf" \
  /etc/sysctl.d/99-zram.conf

sudo sysctl --system

echo "Installed zram configuration. Reboot to recreate /dev/zram0 safely."

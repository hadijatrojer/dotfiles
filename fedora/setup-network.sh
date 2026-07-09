#!/usr/bin/env bash
set -euo pipefail

# Install host network tweaks from fedora/etc into /etc and reload the
# affected services. Currently: disable Wi-Fi power save for smoother
# real-time calls (Google Meet, etc.).

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
src="${script_dir}/etc/NetworkManager/conf.d/wifi-powersave.conf"
dst="/etc/NetworkManager/conf.d/wifi-powersave.conf"

sudo install -D -m 0644 "${src}" "${dst}"
sudo systemctl restart NetworkManager

echo "Installed ${dst} and restarted NetworkManager."
echo "Verify with: iw dev wlp2s0 get power_save"

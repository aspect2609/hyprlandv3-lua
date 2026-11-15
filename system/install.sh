#!/usr/bin/env bash
# Install the system-level tweaks under system/etc into /etc.
# Run with sudo:  sudo system/install.sh
#   tlp.d/                  battery-first TLP profile on AC and battery,
#                           NVIDIA runtime PM, 80-85% charge limit
#   modprobe.d/psmouse-...  Synaptics touchpad over SMBus (intertouch)
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run with sudo: sudo $0" >&2; exit 1; }

src="$(dirname "$(realpath "$0")")/etc"
cd "$src"
find . -type f | while read -r f; do
    install -Dm644 "$f" "/etc/${f#./}"
    echo "installed /etc/${f#./}"
done

command -v tlp >/dev/null && tlp start
echo "Reboot to apply the touchpad change."

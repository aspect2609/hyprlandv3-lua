#!/usr/bin/env bash

COLORS_CSS="/tmp/waybar-colors.css"

# Get wallpaper path
WALLPAPER=$(grep '^wallpaper' ~/.config/waypaper/config.ini | cut -d'=' -f2 | xargs | sed "s|~|$HOME|")
[ -z "$WALLPAPER" ] && exit 1

# Generate palette
wal -i "$WALLPAPER" -n -q --backend haishoku

# Source colors
source "$HOME/.cache/wal/colors.sh"

# Convert color0 hex to rgba with slight transparency
HEX="${color1#\#}"
R=$((16#${HEX:0:2}))
G=$((16#${HEX:2:2}))
B=$((16#${HEX:4:2}))
RGBA="rgba($R, $G, $B, 0.85)"

# Write override CSS atomically: write to a temp file first, then move it
# into place (rename on the same tmpfs is atomic) so a concurrently
# reloading waybar can never read a partially written file.
cat > "${COLORS_CSS}.tmp" << EOF
#window, #mpris, #pulseaudio, #tray,
#idle_inhibitor, #custom-notification,
#custom-power, #custom-weather,
#custom-launcher, #custom-btop, #custom-updates, #workspaces,
#custom-system, #clock, #custom-date,
#custom-keyboard-light, #backlight,
#custom-powerprofile, #battery {
    background-color: ${RGBA};
}
EOF
mv -f "${COLORS_CSS}.tmp" "$COLORS_CSS"

# Reload main waybar only (not dock).
# pgrep -x matches the process *name* exactly. The old "pgrep -af waybar"
# matched any cmdline containing "waybar" (e.g. the autostart shell running
# "theme.sh && waybar") and SIGUSR2-killed it.
for pid in $(pgrep -x waybar); do
    tr '\0' ' ' < "/proc/$pid/cmdline" | grep -q -- '--bar dock' || kill -USR2 "$pid"
done

#!/usr/bin/env bash
# Theme everything from the current wallpaper's pywal palette.
# Runs at login (modules/autostart.lua) and after every wallpaper change
# (waypaper post_command). Writes:
#   /tmp/waybar-colors.css                waybar module backgrounds
#   ~/.cache/wal/colors-rofi-theme.rasi   rofi (imported by rofi/config.rasi)
#   ~/.cache/wal/colors-hyprlock.conf     hyprlock (sourced by hyprlock.conf)
#   ~/.config/wlogout/colors.css          wlogout (imported by style.css)
# kitty includes wal's own colors-kitty.conf; window borders come from
# hypr/modules/theme.lua. If pywal fails, a Tokyo Night palette is used so
# every file above still exists.

COLORS_CSS="/tmp/waybar-colors.css"
WAL="$HOME/.cache/wal"
mkdir -p "$WAL"

# Waypaper starts a new swaybg on every change without stopping the old one;
# keep only the newest (the wallpaper just set) so they don't pile up.
newest=$(pgrep -nx swaybg)
for pid in $(pgrep -x swaybg); do
    [ "$pid" != "$newest" ] && kill "$pid"
done

# Get wallpaper path
WALLPAPER=$(grep '^wallpaper' ~/.config/waypaper/config.ini | cut -d'=' -f2 | xargs | sed "s|~|$HOME|")

# Generate palette (also recolours open terminals via escape sequences)
if [ -n "$WALLPAPER" ] && wal -i "$WALLPAPER" -n -q --backend haishoku; then
    source "$WAL/colors.sh"
else
    background='#1a1b26' foreground='#c0caf5'
    color0='#15161e' color1='#f7768e' color4='#7aa2f7'
    color5='#bb9af7' color7='#a9b1d6' color8='#414868'
fi

# Write a file atomically: write to a temp file first, then move it into
# place (rename on the same filesystem is atomic) so a reader can never see
# a partially written file.
write() { cat > "$1.tmp" && mv -f "$1.tmp" "$1"; }

hex_rgba() {  # #rrggbb alpha -> rgba(r, g, b, alpha)
    local h="${1#\#}"
    echo "rgba($((16#${h:0:2})), $((16#${h:2:2})), $((16#${h:4:2})), $2)"
}

# --- waybar ---
write "$COLORS_CSS" << EOF
#window, #mpris, #pulseaudio, #tray,
#idle_inhibitor, #custom-notification,
#custom-power, #custom-weather,
#custom-launcher, #custom-btop, #custom-updates, #workspaces,
#custom-system, #clock, #custom-date,
#custom-keyboard-light, #backlight,
#custom-powerprofile, #battery {
    background-color: $(hex_rgba "$color1" 0.85);
}
EOF

# --- rofi: override the colour variables of themes/tokyo-night.rasi ---
write "$WAL/colors-rofi-theme.rasi" << EOF
* {
    bg0:        ${background};
    bg1:        ${color0};
    bg2:        ${color8};
    border-col: ${color8};
    accent:     ${color4};
    accent2:    ${color5};
    fg0:        ${foreground};
    fg1:        ${color7};
    fg2:        ${color8};
    glass:      ${background}e0;
}
EOF

# --- hyprlock ---
write "$WAL/colors-hyprlock.conf" << EOF
\$wal_accent = rgb(${color4#\#})
\$wal_fg     = rgb(${foreground#\#})
\$wal_bg     = rgb(${color0#\#})
\$wal_wallpaper = ${WALLPAPER}
EOF

# --- wlogout ---
write "$HOME/.config/wlogout/colors.css" << EOF
@define-color wal_bg     ${background};
@define-color wal_button ${color0};
@define-color wal_accent ${color4};
@define-color wal_fg     ${foreground};
EOF

# --- Hyprland window borders ---
hyprctl eval 'require("modules.theme").apply()' >/dev/null 2>&1

# Reload main waybar only (not dock).
# pgrep -x matches the process *name* exactly. The old "pgrep -af waybar"
# matched any cmdline containing "waybar" (e.g. the autostart shell running
# "theme.sh && waybar") and SIGUSR2-killed it.
for pid in $(pgrep -x waybar); do
    tr '\0' ' ' < "/proc/$pid/cmdline" | grep -q -- '--bar dock' || kill -USR2 "$pid"
done

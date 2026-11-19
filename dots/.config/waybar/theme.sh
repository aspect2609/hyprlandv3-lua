#!/usr/bin/env bash
# Theme everything from the current wallpaper's pywal palette.
# Runs at login (modules/autostart.lua) and after every wallpaper change
# (hypr/scripts/wallpaper.sh). Writes:
#   /tmp/waybar-colors.css                waybar module backgrounds
#   ~/.cache/wal/colors-rofi-theme.rasi   rofi (imported by rofi/config.rasi)
#   ~/.cache/wal/colors-hyprlock.conf     hyprlock (sourced by hyprlock.conf)
#   ~/.config/wlogout/colors.css          wlogout (imported by style.css)
#   ~/.cache/wal/colors-gtk.css           GTK 3/4 apps (imported by gtk.css)
#   ~/.cache/wal/colors-swaync.css        swaync (imported by style.css)
# and recolours Firefox through pywalfox.
# kitty includes wal's own colors-kitty.conf; window borders come from
# hypr/modules/theme.lua. If pywal fails, a Tokyo Night palette is used so
# every file above still exists.

COLORS_CSS="/tmp/waybar-colors.css"
WAL="$HOME/.cache/wal"
mkdir -p "$WAL"

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
# Relative luminance (WCAG) of #rrggbb, and the contrast ratio of two of them.
lum() {
    local h="${1#\#}"
    awk -v r=$((16#${h:0:2})) -v g=$((16#${h:2:2})) -v b=$((16#${h:4:2})) '
        function c(v) { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
        BEGIN { printf "%.4f", 0.2126 * c(r) + 0.7152 * c(g) + 0.0722 * c(b) }'
}
contrast() { awk -v a="$1" -v b="$2" 'BEGIN { if (a < b) { t = a; a = b; b = t }; printf "%.2f", (a + 0.05) / (b + 0.05) }'; }

# Clock colour: the accent, unless it blends into the part of the wallpaper
# behind the clock and date (top centre, see hyprlock.conf); then whichever
# of foreground / color0 stands out more.
clock="$color4"
res=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0] | "\(.width)x\(.height)"')
if [ -n "$WALLPAPER" ] && [[ "$res" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    W=${BASH_REMATCH[1]} H=${BASH_REMATCH[2]}
    area=$(magick "$WALLPAPER[0]" -resize "${res}^" -gravity center -extent "$res" +gravity \
        -crop "$((W * 3 / 8))x$((H * 2 / 9))+$((W * 5 / 16))+$((H * 2 / 9))" +repage \
        -scale '1x1!' -format '%[hex:p{0,0}]' info: 2>/dev/null)
    if [ -n "$area" ]; then
        behind=$(lum "#${area:0:6}")
        best=$(contrast "$(lum "$color4")" "$behind")
        if awk -v c="$best" 'BEGIN { exit !(c < 3) }'; then
            best=0
            for c in "$foreground" "$color0"; do
                r=$(contrast "$(lum "$c")" "$behind")
                if awk -v a="$r" -v b="$best" 'BEGIN { exit !(a > b) }'; then
                    best=$r clock=$c
                fi
            done
        fi
    fi
fi

write "$WAL/colors-hyprlock.conf" << EOF
\$wal_accent = rgb(${color4#\#})
\$wal_clock  = rgb(${clock#\#})
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

# --- GTK 3/4 (adw-gtk3 / libadwaita named colours) ---
write "$WAL/colors-gtk.css" << EOF
@define-color accent_color ${color4};
@define-color accent_bg_color ${color4};
@define-color accent_fg_color ${background};
@define-color window_bg_color ${background};
@define-color window_fg_color ${foreground};
@define-color view_bg_color ${color0};
@define-color view_fg_color ${foreground};
@define-color headerbar_bg_color ${color0};
@define-color headerbar_fg_color ${foreground};
@define-color sidebar_bg_color ${color0};
@define-color sidebar_fg_color ${foreground};
@define-color popover_bg_color ${color0};
@define-color popover_fg_color ${foreground};
@define-color card_bg_color $(hex_rgba "$color8" 0.25);
@define-color card_fg_color ${foreground};
@define-color dialog_bg_color ${background};
@define-color dialog_fg_color ${foreground};
EOF

# --- swaync: override the stock theme's colour variables ---
write "$WAL/colors-swaync.css" << EOF
@define-color cc-bg $(hex_rgba "$background" 0.85);
@define-color noti-bg $(hex_rgba "$color0" 0.9);
@define-color noti-bg-opaque ${color0};
@define-color noti-bg-darker ${background};
@define-color noti-bg-hover ${color8};
@define-color noti-bg-hover-opaque ${color8};
@define-color noti-bg-focus $(hex_rgba "$color8" 0.6);
@define-color noti-border-color $(hex_rgba "$color4" 0.4);
@define-color text-color ${foreground};
@define-color bg-selected ${color4};
@define-color wal-accent ${color4};
@define-color wal-bg ${background};
EOF
swaync-client -rs >/dev/null 2>&1

# --- Firefox (needs the Pywalfox add-on) ---
command -v pywalfox >/dev/null && { pywalfox update >/dev/null 2>&1 & }

# --- Hyprland window borders ---
hyprctl eval 'require("modules.theme").apply()' >/dev/null 2>&1

# Reload main waybar only (not dock).
# pgrep -x matches the process *name* exactly. The old "pgrep -af waybar"
# matched any cmdline containing "waybar" (e.g. the autostart shell running
# "theme.sh && waybar") and SIGUSR2-killed it.
for pid in $(pgrep -x waybar); do
    tr '\0' ' ' < "/proc/$pid/cmdline" | grep -q -- '--bar dock' || kill -USR2 "$pid"
done

#!/usr/bin/env bash
# Set the wallpaper with an awww transition, remember it, and re-theme.
#   wallpaper.sh <image>    set a new wallpaper (then runs waybar/theme.sh)
#   wallpaper.sh --restore  show the remembered one (at login; autostart
#                           runs theme.sh itself before waybar)
# The current wallpaper is kept in waypaper's config.ini, which theme.sh and
# the picker read.

CONF="$HOME/.config/waypaper/config.ini"

current() { grep '^wallpaper' "$CONF" | cut -d'=' -f2 | xargs | sed "s|~|$HOME|"; }

if [ "$1" = --restore ]; then
    img=$(current)
else
    img=$(realpath "$1")
fi
[ -f "$img" ] || { echo "No such image: $img" >&2; exit 1; }

if ! awww query >/dev/null 2>&1; then
    # --no-cache: otherwise the daemon restores its own last image over ours
    awww-daemon --no-cache >/dev/null 2>&1 &
    for _ in $(seq 50); do awww query >/dev/null 2>&1 && break; sleep 0.1; done
fi

awww img "$img" --transition-type any --transition-fps 60 --transition-duration 1

[ "$1" = --restore ] && exit
sed -i --follow-symlinks "s|^wallpaper = .*|wallpaper = ${img/#$HOME/\~}|" "$CONF"
~/.config/waybar/theme.sh

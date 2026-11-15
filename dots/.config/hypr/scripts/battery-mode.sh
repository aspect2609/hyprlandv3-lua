#!/usr/bin/env bash
# Turn off blur/shadows/animations on battery, restore them on AC.
# Started once from hyprland.lua; reacts to plug/unplug events (no polling).

on_ac() {
    for f in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [ -r "$f" ] && [ "$(cat "$f")" = 1 ] && return 0
    done
    return 1
}

apply() {
    if on_ac; then v=true; else v=false; fi
    # Lua config provider: `hyprctl keyword` is unsupported, use eval instead.
    hyprctl eval "hl.config({ decoration = { blur = { enabled = $v }, shadow = { enabled = $v } }, animations = { enabled = $v } })" >/dev/null 2>&1
}

# Only one instance
exec 9>/tmp/battery-mode.lock
flock -n 9 || exit 0

apply
udevadm monitor --udev --subsystem-match=power_supply 2>/dev/null | while read -r _; do
    sleep 1   # let the state settle after the event burst
    apply
done

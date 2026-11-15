#!/usr/bin/env bash
# Battery saver. Started once from modules/autostart.lua; reacts to
# plug/unplug events (no polling).
#   - blur/shadows/animations/VRR: modules/power.lua (shared with config load)
#   - brightness: capped at $CAP on unplug, previous level restored on plug-in

CAP=40
SAVED="${XDG_RUNTIME_DIR:-/tmp}/battery-mode.brightness"

on_ac() {
    for f in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [ -r "$f" ] && [ "$(cat "$f")" = 1 ] && return 0
    done
    return 1
}

pct() { brightnessctl -m | cut -d, -f4 | tr -d %; }

apply() {
    hyprctl eval 'require("modules.power").apply()' >/dev/null 2>&1
    if on_ac; then
        [ -f "$SAVED" ] && brightnessctl -q set "$(cat "$SAVED")" && rm -f "$SAVED"
    elif [ "$(pct)" -gt "$CAP" ]; then
        brightnessctl -m | cut -d, -f3 > "$SAVED"
        brightnessctl -q set "$CAP%"
    fi
}

# Only one instance
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/battery-mode.lock"
flock -n 9 || exit 0

# Battery level updates also fire power_supply events; act only when the
# power source actually changes, so a manual brightness change sticks.
last=""
check() {
    if on_ac; then now=ac; else now=bat; fi
    [ "$now" = "$last" ] && return
    last=$now
    apply
}

# At startup only sync Hyprland; don't touch brightness the user already chose.
on_ac && last=ac || last=bat
hyprctl eval 'require("modules.power").apply()' >/dev/null 2>&1

udevadm monitor --udev --subsystem-match=power_supply 2>/dev/null | while read -r _; do
    sleep 1   # let the state settle after the event burst
    check
done

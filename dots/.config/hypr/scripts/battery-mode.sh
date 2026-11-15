#!/usr/bin/env bash
# Battery saver. Started once from modules/autostart.lua; reacts to
# plug/unplug events (no polling).
#   - blur/shadows/animations/VRR: modules/power.lua (shared with config load)
#   - brightness: capped at $CAP on unplug, previous level restored on plug-in
#   - notifications at $WARN% and $CRIT% while discharging

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

# Low battery warnings, once per threshold per discharge.
WARN=20
CRIT=10
warned=100
warn() {
    if on_ac; then warned=100; return; fi
    local cap
    cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
    [ -n "$cap" ] || return
    if [ "$cap" -le "$CRIT" ] && [ "$warned" -gt "$CRIT" ]; then
        warned=$CRIT
        notify-send -u critical -i battery-caution "Battery critical: ${cap}%" "Plug in now."
    elif [ "$cap" -le "$WARN" ] && [ "$warned" -gt "$WARN" ]; then
        warned=$WARN
        notify-send -u normal -i battery-low "Battery low: ${cap}%" "Plug in soon."
    fi
}

# At startup only sync Hyprland; don't touch brightness the user already chose.
on_ac && last=ac || last=bat
hyprctl eval 'require("modules.power").apply()' >/dev/null 2>&1
warn

# React to power_supply events; the 60s timeout also catches battery levels
# that change without an event.
while true; do
    read -r -t 60 _
    status=$?
    [ "$status" -eq 0 ] || [ "$status" -gt 128 ] || break   # udevadm exited
    [ "$status" -eq 0 ] && sleep 1   # let the state settle after the event burst
    check
    warn
done < <(udevadm monitor --udev --subsystem-match=power_supply 2>/dev/null)

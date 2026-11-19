#!/usr/bin/env bash
# Lock the screen (SUPER + L, and hypridle's lock_cmd).
# A hyprlock that was just unlocked by fingerprint keeps the scanner claimed
# while it exits; a new one started in that moment can't claim it and is
# password-only. So wait for the old one to go first. If it's still there
# after 3s, the screen is genuinely locked and there's nothing to do.
# hyprlock's output goes to $XDG_RUNTIME_DIR/hyprlock.log for debugging.

for _ in $(seq 30); do
    pidof hyprlock >/dev/null || exec hyprlock >"${XDG_RUNTIME_DIR:-/tmp}/hyprlock.log" 2>&1
    sleep 0.1
done

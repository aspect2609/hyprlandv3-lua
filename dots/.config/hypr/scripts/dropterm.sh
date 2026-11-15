#!/usr/bin/env bash
# Drop-down terminal (SUPER + `). Lives on special:dropterm; window rule and
# hide-on-focus-loss are in modules/dropterm.lua, Esc-to-hide in .zshrc
# (keyed off DROPTERM=1).

toggle() { hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropterm")' >/dev/null; }

if hyprctl clients -j | grep -q '"class": "dropterm"'; then
    toggle
else
    # Open the (empty) special workspace first so the new window lands in it.
    toggle
    kitty --class dropterm -o env=DROPTERM=1 &
fi

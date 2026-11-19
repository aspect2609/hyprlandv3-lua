#!/usr/bin/env bash
# Drop-down terminal (SUPER + `). Opens on special:dropterm, and closes
# (rather than hides) on the next press, so it never runs in the background.
# Window rule and close-on-focus-loss are in modules/dropterm.lua,
# Esc-to-close in .zshrc (keyed off DROPTERM=1).

if hyprctl clients -j | grep -q '"class": "dropterm"'; then
    hyprctl dispatch 'hl.dsp.window.close({ window = "class:dropterm" })' >/dev/null
    exit
fi

shown=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')
[ "$shown" != "special:dropterm" ] && hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropterm")' >/dev/null
kitty --class dropterm -o env=DROPTERM=1 -o shell=/usr/bin/zsh &

# A window placed by a workspace rule doesn't take focus, so give it focus
# once it appears.
for _ in $(seq 30); do
    if hyprctl clients -j | grep -q '"class": "dropterm"'; then
        hyprctl dispatch 'hl.dsp.focus({ window = "class:dropterm" })' >/dev/null
        break
    fi
    sleep 0.1
done

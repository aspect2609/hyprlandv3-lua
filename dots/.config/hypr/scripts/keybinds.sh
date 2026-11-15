#!/usr/bin/env bash
# Searchable keybind cheat sheet, built from the live binds so it always
# matches modules/keybinds.lua.

pkill -x rofi && exit 0   # pressing the key again closes it

hyprctl binds -j | python3 -c '
import json, sys
MODS = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")]
NAMES = {"mouse:272": "LMB drag", "mouse:273": "RMB drag", "mouse_down": "Scroll down",
         "mouse_up": "Scroll up", "slash": "/", "grave": "`", "RETURN": "Enter"}
for b in json.load(sys.stdin):
    if not b["has_description"]:
        continue
    keys = [n for m, n in MODS if b["modmask"] & m]
    keys.append(NAMES.get(b["key"], b["key"].removeprefix("XF86")))
    print(" + ".join(keys).ljust(26) + b["description"])
' | rofi -dmenu -i -p "Keybinds" -no-custom \
       -theme-str 'window { width: 640px; } listview { lines: 14; } * { font: "JetBrainsMono Nerd Font 11"; }' \
       >/dev/null

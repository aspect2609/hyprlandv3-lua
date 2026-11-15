# hyprlandv3-lua

Hyprland rice with native Lua config (Hyprland 0.57+).

## Install

```sh
git clone https://github.com/aspect2609/hyprlandv3-lua.git
cd hyprlandv3-lua
./stow.sh
```

## Layout

Hyprland config lives in `dots/.config/hypr/`:

- `hyprland.lua` — entry point; loads each file in `modules/`
- `modules/` — monitors, env, autostart, look, power, theme, input, keybinds, rules, programs
- `scripts/battery-mode.sh` — battery saver: no blur/shadows/animations, VRR on,
  brightness capped at 40% (restored on plug-in)
- `scripts/keybinds.sh` — `SUPER + /` searchable cheat sheet of every bind
- `hypridle.conf`, `hyprlock.conf` — these tools still use hyprlang `.conf`

## Features

- **Wallpaper theming** — `waybar/theme.sh` runs pywal on each wallpaper change
  and recolours waybar, kitty, rofi, hyprlock, wlogout and window borders
- **OSD** — swayosd popups for volume/brightness keys
- **Power menu** — `SUPER + Escape` (wlogout)

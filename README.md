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
- `modules/` — monitors, env, autostart, look, input, keybinds, rules, programs
- `scripts/battery-mode.sh` — turns off blur/shadows/animations on battery
- `hypridle.conf`, `hyprlock.conf` — these tools still use hyprlang `.conf`

# hyprlandv3-lua

Hyprland rice with native Lua config (Hyprland 0.57+).

## Install

```sh
git clone https://github.com/aspect2609/hyprlandv3-lua.git
cd hyprlandv3-lua
./stow.sh
sudo system/install.sh   # TLP power profile, charge limit, touchpad mode
```

`system/etc/` holds the files that live outside `$HOME` (`/etc/tlp.d`,
`/etc/modprobe.d`); `install.sh` copies them into place.

## Layout

Hyprland config lives in `dots/.config/hypr/`:

- `hyprland.lua` — entry point; loads each file in `modules/`
- `modules/` — monitors, env, autostart, look, power, theme, input, keybinds, rules, dropterm, programs
- `scripts/battery-mode.sh` — battery saver: no blur/shadows/animations, VRR on,
  brightness capped at 40% (restored on plug-in), low battery warnings at 20%/10%
- `scripts/keybinds.sh` — `SUPER + /` searchable cheat sheet of every bind
- `scripts/wallpaper-picker.sh` — `SUPER + W` thumbnail grid of `~/Pictures/Wallpapers` (type to filter)
- `scripts/dropterm.sh` — ``SUPER + ` `` drop-down terminal (Esc or clicking another window hides it)
- `scripts/media-inhibit.sh` — no dim/lock/screen-off while media is playing
- `hypridle.conf`, `hyprlock.conf` — these tools still use hyprlang `.conf`

## Features

- **Wallpaper theming** — `waybar/theme.sh` runs pywal on each wallpaper change
  and recolours waybar, kitty, rofi, hyprlock, wlogout and window borders
- **OSD** — swayosd popups for volume/brightness keys
- **Power menu** — `SUPER + Escape` (wlogout)

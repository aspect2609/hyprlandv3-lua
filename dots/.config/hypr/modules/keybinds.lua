local apps = require("modules.programs")

local mainMod = "SUPER"

-- Every bind carries a description; SUPER + / lists them (scripts/keybinds.sh).
local function bind(keys, description, dispatcher, opts)
    opts = opts or {}
    opts.description = description
    hl.bind(keys, dispatcher, opts)
end

local function mod(keys) return mainMod .. " + " .. keys end

-- Apps
bind(mod("Q"),              "Terminal",         hl.dsp.exec_cmd(apps.terminal))
bind(mod("grave"),          "Drop-down terminal", hl.dsp.exec_cmd("~/.config/hypr/scripts/dropterm.sh"))
bind(mod("B"),              "Browser",          hl.dsp.exec_cmd(apps.browser))
bind(mod("RETURN"),         "Code editor",      hl.dsp.exec_cmd(apps.code))
bind(mod("SPACE"),          "Spotlight search", hl.dsp.exec_cmd(apps.appmanager))
bind(mod("CTRL + RETURN"),  "App launcher",     hl.dsp.exec_cmd(apps.appmanager))
bind(mod("E"),              "File manager",     hl.dsp.exec_cmd(apps.fileManager))
bind(mod("R"),              "Run menu",         hl.dsp.exec_cmd(apps.menu))

-- Session
bind(mod("L"),              "Lock screen",      hl.dsp.exec_cmd("hyprlock"))
bind(mod("Escape"),         "Power menu",       hl.dsp.exec_cmd("pidof wlogout || wlogout -b 3"))
bind(mod("M"),              "Exit Hyprland",    hl.dsp.exec_cmd('command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch "hl.dsp.exit()"'))
bind(mod("slash"),          "Show keybinds",    hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds.sh"))

-- Desktop
bind(mod("SHIFT + B"),      "Reload waybar",     hl.dsp.exec_cmd("~/.config/waybar/reload.sh"))
bind(mod("SHIFT + S"),      "Random wallpaper",  hl.dsp.exec_cmd("~/.config/waypaper/randomize.sh"))
bind(mod("W"),              "Pick wallpaper",    hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-picker.sh"))
bind(mod("Print"),          "Screenshot region", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
bind(mod("SHIFT + Print"),  "Screenshot region (annotate)", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty --filename - --copy-command wl-copy --early-exit'))
bind("Print",               "Screenshot full screen", hl.dsp.exec_cmd("grim - | wl-copy"))
bind(mod("N"),              "Notification panel", hl.dsp.exec_cmd("swaync-client -t -sw"))
bind(mod("SHIFT + V"),      "Clipboard history", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p clipboard -display-columns 2 | cliphist decode | wl-copy"))
bind(mod("SHIFT + C"),      "Colour picker",     hl.dsp.exec_cmd("hyprpicker -a"))

-- Windows
bind(mod("C"),              "Close window",        hl.dsp.window.close())
bind(mod("V"),              "Toggle floating",     hl.dsp.window.float({ action = "toggle" }))
bind(mod("P"),              "Pseudo-tile",         hl.dsp.window.pseudo())
bind(mod("J"),              "Toggle split",        hl.dsp.layout("togglesplit"))
bind(mod("F"),              "Fullscreen",          hl.dsp.window.fullscreen())
bind(mod("SHIFT + F"),      "Maximize",            hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mod("left"),           "Focus left",          hl.dsp.focus({ direction = "left" }))
bind(mod("right"),          "Focus right",         hl.dsp.focus({ direction = "right" }))
bind(mod("up"),             "Focus up",            hl.dsp.focus({ direction = "up" }))
bind(mod("down"),           "Focus down",          hl.dsp.focus({ direction = "down" }))
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    bind(mod("SHIFT + " .. dir), "Swap window " .. dir, hl.dsp.window.swap({ direction = dir }))
end
-- Hold to keep resizing
local step = 40
local resize = { left = { -step, 0 }, right = { step, 0 }, up = { 0, -step }, down = { 0, step } }
for dir, d in pairs(resize) do
    bind(mod("CTRL + " .. dir), "Resize window " .. dir,
        hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end
bind(mod("mouse:272"),      "Move window (drag)",  hl.dsp.window.drag(),   { mouse = true })
bind(mod("mouse:273"),      "Resize window (drag)", hl.dsp.window.resize(), { mouse = true })

-- Workspaces: mainMod + [1-0] switches, mainMod + SHIFT + [1-0] moves the window
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(mod(key),             "Workspace " .. i,              hl.dsp.focus({ workspace = i }))
    bind(mod("SHIFT + " .. key), "Move window to workspace " .. i, hl.dsp.window.move({ workspace = i }))
end

bind(mod("S"),              "Toggle special workspace",       hl.dsp.workspace.toggle_special("magic"))
bind(mod("SHIFT + X"),      "Move window to special workspace", hl.dsp.window.move({ workspace = "special:magic" }))
bind(mod("mouse_down"),     "Next workspace",                 hl.dsp.focus({ workspace = "e+1" }))
bind(mod("mouse_up"),       "Previous workspace",             hl.dsp.focus({ workspace = "e-1" }))

-- Laptop multimedia keys, with on-screen popups from swayosd
local held = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume",  "Volume up",       hl.dsp.exec_cmd("swayosd-client --output-volume raise --max-volume 100"), held)
bind("XF86AudioLowerVolume",  "Volume down",     hl.dsp.exec_cmd("swayosd-client --output-volume lower"),       held)
bind("XF86AudioMute",         "Mute",            hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), held)
bind("XF86AudioMicMute",      "Mute microphone", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  held)
bind("XF86MonBrightnessUp",   "Brightness up",   hl.dsp.exec_cmd("swayosd-client --brightness +5"),             held)
bind("XF86MonBrightnessDown", "Brightness down", hl.dsp.exec_cmd("swayosd-client --brightness -5 --min-brightness 2"), held)

-- Requires playerctl
bind("XF86AudioNext",  "Next track",     hl.dsp.exec_cmd("playerctl next"),       { locked = true })
bind("XF86AudioPause", "Play/pause",     hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay",  "Play/pause",     hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev",  "Previous track", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

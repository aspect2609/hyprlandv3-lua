-- Hyprland entry point (Lua config, Hyprland >= 0.55).
-- Each section lives in modules/<name>.lua; ~/.config/hypr is on package.path.

-- Drop cached modules so `hyprctl reload` picks up edits.
for name in pairs(package.loaded) do
    if name:match("^modules%.") then package.loaded[name] = nil end
end

require("modules.monitors")
require("modules.env")
require("modules.autostart")
require("modules.look")
require("modules.power")
require("modules.theme")
require("modules.input")
require("modules.keybinds")
require("modules.rules")

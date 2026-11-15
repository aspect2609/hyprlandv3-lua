-- Window border colours from the current wallpaper's pywal palette.
-- Applied on config load, and by waybar/theme.sh after each wallpaper change via
--   hyprctl eval 'require("modules.theme").apply()'
-- Falls back to the borders in look.lua when there is no palette yet.

local M = {}

local function wal_colors()
    local f = io.open(os.getenv("HOME") .. "/.cache/wal/colors.sh")
    if not f then return nil end
    local c = {}
    for line in f:lines() do
        local k, v = line:match("^(%w+)='#(%x+)'")
        if k then c[k] = v end
    end
    f:close()
    return c
end

function M.apply()
    local c = wal_colors()
    if not (c and c.color4 and c.color0) then return end
    hl.config({
        general = {
            col = {
                active_border   = "rgba(" .. c.color4 .. "ee)",
                inactive_border = "rgba(" .. c.color0 .. "aa)",
            },
        },
    })
end

M.apply()

return M

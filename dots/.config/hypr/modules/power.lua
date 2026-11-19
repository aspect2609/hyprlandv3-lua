-- Battery saver: eye candy and VRR follow the power source.
-- Applied on config load, and by scripts/battery-mode.sh on plug/unplug via
--   hyprctl eval 'require("modules.power").apply()'

local M = {}

function M.on_ac()
    for _, name in ipairs({ "AC", "ADP0", "ADP1", "ACAD" }) do
        local f = io.open("/sys/class/power_supply/" .. name .. "/online")
        if f then
            local v = f:read("l")
            f:close()
            if v == "1" then return true end
        end
    end
    return false
end

function M.apply()
    local ac = M.on_ac()
    hl.config({
        decoration = {
            blur   = { enabled = ac },
            shadow = { enabled = ac },
        },
        animations = { enabled = ac },
        -- VRR lets the panel drop its refresh rate when nothing is moving.
        misc = { vrr = ac and 0 or 1 },
    })
end

M.apply()

-- Lid: blank the panel on close, wake it on open. logind still suspends on
-- close; the DPMS off->on cycle forces a full repaint on open, so hyprlock
-- shows the current time immediately instead of the pre-suspend frame.
hl.bind("switch:on:Lid Switch",  hl.dsp.dpms({ action = "off" }), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "on" }),  { locked = true })

return M

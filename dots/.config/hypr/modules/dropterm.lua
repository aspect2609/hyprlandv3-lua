-- Drop-down terminal (SUPER + `), opened by scripts/dropterm.sh onto
-- special:dropterm. Esc at the shell prompt closes it (see .zshrc).

hl.window_rule({
    name = "dropterm",
    match = { class = "^(dropterm)$" },
    workspace = "special:dropterm",
    float = true,
    size = "(monitor_w*0.8) (monitor_h*0.5)",
    move = "(monitor_w*0.1) 50",
})

-- Close it when keyboard focus moves to another window, so it never lingers
-- in the background.
hl.on("window.active", function(win)
    if not win or win.class == "dropterm" then return end
    if hl.get_window("class:dropterm") then
        hl.dispatch(hl.dsp.window.close({ window = "class:dropterm" }))
    end
end)

-- Clicking a window behind it doesn't move focus while the special workspace
-- is shown, so the handler above never fires. Watch left clicks instead (the
-- click still goes through) and close it when one lands outside it.
local function inside(win, p)
    return p.x >= win.at.x and p.x < win.at.x + win.size.x
       and p.y >= win.at.y and p.y < win.at.y + win.size.y
end

local click
click = hl.bind("mouse:272", function()
    local win = hl.get_window("class:dropterm")
    if not win then return click:set_enabled(false) end
    local cursor = hl.get_cursor_pos()
    if cursor and not inside(win, cursor) then
        hl.dispatch(hl.dsp.window.close({ window = "class:dropterm" }))
    end
end, { non_consuming = true, description = "Close drop-down terminal on click outside" })
click:set_enabled(hl.get_window("class:dropterm") ~= nil)

hl.on("window.open", function(win)
    if win and win.class == "dropterm" then click:set_enabled(true) end
end)

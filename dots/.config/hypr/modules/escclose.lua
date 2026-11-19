-- Esc closes the small floating utility windows (volume, bluetooth, network),
-- so they quit instead of lingering. The bind is only enabled while one of
-- them is focused; everywhere else Esc reaches the app as normal.

local closable = {
    ["org.pulseaudio.pavucontrol"] = true,
    ["blueman-manager"]            = true,
    ["nm-connection-editor"]       = true,
}

local esc = hl.bind("Escape", hl.dsp.window.close(), { description = "Close utility window (Esc)" })
esc:set_enabled(false)

hl.on("window.active", function(win)
    esc:set_enabled(win ~= nil and closable[win.class] == true)
end)

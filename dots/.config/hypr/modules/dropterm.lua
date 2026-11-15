-- Drop-down terminal (SUPER + `), opened by scripts/dropterm.sh onto
-- special:dropterm. Esc at the shell prompt hides it too (see .zshrc).

hl.window_rule({
    name = "dropterm",
    match = { class = "^(dropterm)$" },
    float = true,
    size = "(monitor_w*0.8) (monitor_h*0.5)",
    move = "(monitor_w*0.1) 50",
})

-- Hide it when focus moves to another window, e.g. clicking outside it.
hl.on("window.active", function(win)
    if not win or win.class == "dropterm" then return end
    local special = hl.get_active_special_workspace()
    if special and special.name == "special:dropterm" then
        hl.dispatch(hl.dsp.workspace.toggle_special("dropterm"))
    end
end)

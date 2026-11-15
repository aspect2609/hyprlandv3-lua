hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name = "thunar-opacity",
    match = { class = "^(thunar)$" },
    opacity = "0.85 0.85",
})

hl.window_rule({
    name = "code-opacity",
    match = { class = "^(code-oss)$" },
    opacity = "0.95 0.95",
})

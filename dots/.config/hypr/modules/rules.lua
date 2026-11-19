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

-- Small utility windows float, centred
hl.window_rule({
    name = "float-utilities",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|xdg-desktop-portal-gtk)$" },
    float = true,
    center = true,
    size = "900 600",
})

-- Firefox picture-in-picture: floating, pinned to every workspace
hl.window_rule({
    name = "firefox-pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
})

-- Blur behind the bar, launcher and notifications
hl.layer_rule({
    name = "blur-shell",
    match = { namespace = "^(waybar|rofi|swaync-control-center|swaync-notification-window)$" },
    blur = true,
    ignore_alpha = 0.3,
})

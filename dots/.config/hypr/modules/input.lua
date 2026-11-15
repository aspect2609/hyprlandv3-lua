hl.config({
    input = {
        kb_layout = "gb",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = 0,

        -- MacBook-style touchpad
        touchpad = {
            natural_scroll = true,
            -- Click anywhere: 1 finger = left, 2 = right, 3 = middle
            -- (instead of bottom-corner click zones)
            clickfinger_behavior = true,
            -- PS/2 Synaptics scrolls too fast by default
            scroll_factor = 0.6,
        },
    },
})

-- Slightly quicker pointer with acceleration, touchpad only (TrackPoint and
-- mice keep the global sensitivity). If the touchpad is ever switched to
-- SMBus/intertouch its device name changes; see `hyprctl devices`.
hl.device({
    name = "synps/2-synaptics-touchpad",
    sensitivity = 0.25,
    accel_profile = "adaptive",
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

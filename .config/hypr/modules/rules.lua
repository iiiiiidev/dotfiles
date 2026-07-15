hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
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
    name  = "float-pavucontrol",
    match = { class = "org.pulseaudio.pavucontrol" },
    float = true,
})

hl.window_rule({
    name  = "float-weather",
    match = { class = "wttr%.in" },
    float = true,
})

hl.layer_rule({
    name  = "blur-fuzzel",
    match = { namespace = "^launcher$" },
    blur  = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name  = "blur-swaync-notifications",
    match = { namespace = "^swaync-notification-window$" },
    blur  = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name  = "blur-quickshell-bar",
    match = { namespace = "^quickshell-bar$" },
    blur  = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name  = "blur-swaync-control-center",
    match = { namespace = "^swaync-control-center$" },
    blur  = true,
    ignore_alpha = 0.3,
})

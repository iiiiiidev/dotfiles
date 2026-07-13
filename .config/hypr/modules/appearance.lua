local mocha = require("modules.theme")

hl.config({
    general = {
        gaps_in  = 8,
        gaps_out = 16,

        border_size = 2,

        col = {
            active_border   = { colors = { mocha.rgba(mocha.mauve), mocha.rgba(mocha.blue) }, angle = 45 },
            inactive_border = mocha.rgba(mocha.surface1),
        },

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = mocha.rgba(mocha.crust, "aa"),
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.1696,
            popups   = true,
        },
    },

    group = {
        col = {
            border_active   = mocha.rgba(mocha.mauve),
            border_inactive = mocha.rgba(mocha.surface1),
        },
        groupbar = {
            font_family = mocha.font,
            text_color  = mocha.rgb(mocha.text),
            col = {
                active   = mocha.rgba(mocha.surface0),
                inactive = mocha.rgba(mocha.base),
            },
        },
    },

    misc = {
        font_family             = mocha.font,
        splash_font_family      = mocha.font,
        background_color        = mocha.rgb(mocha.base),
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },
})

local vars = require("variables")
local c    = require("scheme.active")   -- el shell activo puede elegir el teclado (velvet: Ajustes → Atajos)

hl.config({
    input = {
        kb_layout          = c.kbLayout or "es",
        kb_options         = c.kbOptions or "",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,
        focus_on_close     = 1,

        touchpad           = {
            natural_scroll       = true,
            disable_while_typing = vars.touchpadDisableTyping,
            scroll_factor        = vars.touchpadScrollFactor,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },
})

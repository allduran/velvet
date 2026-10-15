local vars = require("variables")
local mode = require("scheme.active")

hl.config({
    decoration = {
        rounding = vars.windowRounding,
        rounding_power = vars.windowRoundingPower,

        blur = {
            enabled           = vars.blurEnabled and mode.blur,
            xray              = vars.blurXray,
            special           = vars.blurSpecialWs,
            ignore_opacity    = true, -- Allows opacity blurring
            new_optimizations = true,
            popups            = vars.blurPopups,
            input_methods     = vars.blurInputMethods,
            size              = vars.blurSize,
            passes            = vars.blurPasses,
        },

        shadow = {
            enabled      = vars.shadowEnabled,
            range        = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color        = vars.shadowColour,
        },
    },
})

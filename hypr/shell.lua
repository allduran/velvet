-- velvet — parte de Hyprland del shell.
-- duran la enlaza en ~/.config/hypr/shell.lua al hacer `duran switch velvet`.
-- Devuelve { theme = … } con los colores y ajustes del modo activo
-- (lo lee scheme/active.lua de tus dotfiles) y aplica las reglas propias de velvet.

-- Paletas y ajustes por modo (mismo trío que Theme en QML)
-- gapsIn/gapsOut: huecos · animations/blur: efectos · vrr: 0 no, 1 siempre, 2 solo pantalla completa
local modes = {
    general = {
        accent = "e60012", accent2 = "0055ff", accent3 = "ffe600",
        onAccent = "ffffff", inactive = "111111", outline = "555555", bg = "0d0d0d",
        gapsIn = 5, gapsOut = 10, animations = true, blur = true, vrr = 0,
    },
    dev = {
        accent = "0055ff", accent2 = "00a6ff", accent3 = "40e0d0",
        onAccent = "ffffff", inactive = "111111", outline = "555555", bg = "0b0d14",
        gapsIn = 3, gapsOut = 6, animations = true, blur = true, vrr = 0,
    },
    art = {
        accent = "ffe600", accent2 = "ffa800", accent3 = "70d600",
        onAccent = "0d0e12", inactive = "111111", outline = "555555", bg = "141310",
        gapsIn = 5, gapsOut = 10, animations = true, blur = true, vrr = 0,
    },
    game = {
        accent = "e60012", accent2 = "ff3b30", accent3 = "b0b3ba",
        onAccent = "ffffff", inactive = "111111", outline = "555555", bg = "0d0d0d",
        gapsIn = 0, gapsOut = 0, animations = false, blur = false, vrr = 2,
    },
}

-- Modo activo (lo escribe el selector de modo)
local f = io.open(os.getenv("HOME") .. "/.local/state/velvet/mode", "r")
local m = f and f:read("l")
if f then f:close() end

-- Reglas propias de velvet: sin animación de Hyprland, velvet anima sus paneles
hl.layer_rule({ match = { namespace = "velvet-.*" }, no_anim = true })

return { theme = modes[m] or modes.general }

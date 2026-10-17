-- velvet — parte de Hyprland del shell.
-- duran la enlaza en ~/.config/hypr/shell.lua al hacer `duran switch velvet`.
-- Devuelve { theme = … } con los colores y ajustes del modo activo
-- (lo lee scheme/active.lua de tus dotfiles: colores, huecos, efectos y teclado)
-- y aplica las reglas propias de velvet.

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

-- Teclado elegido en Ajustes → Atajos → Teclado (lo escribe velvet; no existe hasta tocarlo)
local kb = {}
local kf = io.open(os.getenv("HOME") .. "/.local/state/velvet/keyboard", "r")
if kf then
    for line in kf:lines() do
        local k, v = line:match("^(%w+)=(.*)$")
        if k then kb[k] = v end
    end
    kf:close()
end

-- Look del modo activo (lo escribe velvet en Administrar modos / al cambiar de modo):
-- mode, style (paleta) y huecos/efectos/vrr. Solo cuenta si es del modo que está puesto.
local look = {}
local lf = io.open(os.getenv("HOME") .. "/.local/state/velvet/look", "r")
if lf then
    for line in lf:lines() do
        local k, v = line:match("^(%w+)=(.*)$")
        if k then look[k] = v end
    end
    lf:close()
end
local useLook = m ~= nil and look.mode == m

-- Base: la paleta del estilo (modos propios) o la del modo de serie
local base = (useLook and modes[look.style]) or modes[m] or modes.general
local theme = {}
for k, v in pairs(base) do theme[k] = v end
if useLook then
    theme.gapsIn = tonumber(look.gapsIn) or theme.gapsIn
    theme.gapsOut = tonumber(look.gapsOut) or theme.gapsOut
    theme.animations = look.animations == "1"
    theme.blur = look.blur == "1"
    theme.vrr = tonumber(look.vrr) or theme.vrr
end

theme.kbLayout = (kb.layouts and kb.layouts ~= "") and kb.layouts or nil   -- nil = el de input.lua
theme.kbOptions = kb.options
return { theme = theme }

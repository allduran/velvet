-- Tema del shell activo. duran enlaza su lua en ~/.config/hypr/shell.lua;
-- si no hay ninguno (o falla), se usan estos valores neutros.
local defaults = {
    accent = "888888", accent2 = "aaaaaa", accent3 = "cccccc",
    onAccent = "ffffff", inactive = "111111", outline = "555555", bg = "0d0d0d",
    gapsIn = 5, gapsOut = 10, animations = true, blur = true, vrr = 0,
}

local ok, shell = pcall(require, "shell")
local theme = ok and type(shell) == "table" and type(shell.theme) == "table" and shell.theme or {}

return setmetatable(theme, { __index = defaults })

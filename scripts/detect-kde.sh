#!/usr/bin/env bash
# Si el usuario viene de KDE, la config de inicio usa KWallet en vez del llavero de GNOME:
# así los navegadores Chromium (Vivaldi, Chrome, Brave…) encuentran sus contraseñas guardadas.
# Lo llama hooks/install.sh al instalar la config de inicio. Se puede repetir sin problema.
# Uso: detect-kde.sh [carpeta de hypr]
set -uo pipefail

hypr="${1:-$HOME/.config/hypr}"
env="$hypr/hyprland/env.lua"
execs="$hypr/hyprland/execs.lua"
[ -f "$env" ] && [ -f "$execs" ] || exit 0

# ¿Hay KWallet? (el demonio de Plasma 6 o un monedero ya creado)
command -v kwalletd6 >/dev/null 2>&1 \
    || [ -d "$HOME/.local/share/kwalletd" ] \
    || [ -f "$HOME/.config/kwalletrc" ] \
    || exit 0

# Chromium elige KWallet si el escritorio incluye KDE
if ! grep -q '"Hyprland:KDE"' "$env"; then
    sed -i '/CURRENT_DESKTOP/s|"Hyprland"|"Hyprland:KDE"|' "$env"
    sed -i '/CURRENT_DESKTOP/a hl.env("KDE_SESSION_VERSION", "6")' "$env"
fi

# KWallet se desbloquea con la contraseña de inicio de sesión (pam_kwallet), igual que en Plasma
if [ -x /usr/lib/pam_kwallet_init ]; then
    sed -i 's|gnome-keyring-daemon.*secrets|/usr/lib/pam_kwallet_init|' "$execs"
fi

printf '      %s\n' "KDE detectado: contraseñas con KWallet"
exit 0

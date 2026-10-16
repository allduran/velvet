#!/usr/bin/env bash
# Instalación de velvet: lo que no son paquetes (los instala `duran install` desde shell.toml).
# Idempotente: no pisa nada que ya exista.
set -euo pipefail

step() { printf '  \e[1;34m·\e[0m %s\n' "$*"; }

root="$(dirname "$(realpath "$0")")/.."
scripts="$root/scripts"
state="$HOME/.local/state/velvet"
hypr="$HOME/.config/hypr"

# Hyprland: si no hay config, se instala la de inicio de velvet (ya preparada para duran)
if [ ! -e "$hypr/hyprland.lua" ] && [ ! -e "$hypr/hyprland.conf" ]; then
    step "Hyprland sin configurar: instalando la config de inicio en $hypr"
    mkdir -p "$hypr"
    cp -r --update=none "$root/hypr/starter/." "$hypr/"
    step "apps de tu sistema → variables.lua"
    bash "$scripts/detect-apps.sh" "$hypr/variables.lua" || true
    bash "$scripts/detect-kde.sh" "$hypr" || true
else
    step "Hyprland ya configurado: no se toca (mira el README para integrarlo)"
fi
[ -e "$hypr/hyprsunset.conf" ] || cp "$root/hypr/starter/hyprsunset.conf" "$hypr/"

# Brillo de monitores externos (ddcutil)
step "módulo i2c-dev + grupo i2c"
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
sudo modprobe i2c-dev
getent group i2c >/dev/null || sudo groupadd i2c
id -nG "$USER" | grep -qw i2c || sudo usermod -aG i2c "$USER"

# Perfiles de energía (por modo, y selector del menú de pausa)
step "power-profiles-daemon (sin TLP)"
systemctl list-unit-files tlp.service >/dev/null 2>&1 && sudo systemctl disable --now tlp.service 2>/dev/null || true
sudo systemctl enable --now power-profiles-daemon.service

# Gamemode (modo GAME)
step "gamemode"
if getent group gamemode >/dev/null; then
    id -nG "$USER" | grep -qw gamemode || sudo usermod -aG gamemode "$USER"
fi

# velvet pinta su propio fondo
step "hyprpaper desactivado"
systemctl --user disable --now hyprpaper.service 2>/dev/null || true
pkill -x hyprpaper 2>/dev/null || true

# Carpetas que usa
step "carpetas"
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings" "$state"
chmod +x "$scripts"/*.sh

# Modo inicial (lo leen velvet y Hyprland)
[ -f "$state/mode" ] || echo general > "$state/mode"

# Colores de terminal del modo GENERAL (luego velvet los regenera según el modo)
step "colores de terminal (foot + fastfetch)"
bash "$scripts/term.sh" e60012 0055ff ffe600

# Bloqueo por inactividad: hypridle.conf lo genera velvet (Ajustes → Energía)
step "hypridle (5 min bloquear · 10 min pantalla)"
[ -e "$hypr/hypridle.conf" ] || touch "$hypr/hypridle.conf"
bash "$scripts/idle.sh" 5 10 0 || true
systemctl --user enable --now hypridle.service 2>/dev/null || true

step "velvet instalado (cierra sesión si te ha añadido a i2c o gamemode)"
cat <<'EOF'

  Opcional, para que la terminal siga los colores del modo:
    foot:  primera línea de ~/.config/foot/foot.ini → include=~/.local/state/velvet/foot-colors.ini
    fish:  function fish_greeting; fastfetch -c ~/.local/state/velvet/fastfetch.jsonc; end
EOF

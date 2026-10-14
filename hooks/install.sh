#!/usr/bin/env bash
# Instalación de velvet: lo que no resuelve stow. Idempotente.
# Refleja lo declarado en ../shell.toml (cuando exista el CLI, lo hará él).
set -euo pipefail

step() { printf '  \e[1;34m·\e[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

here="$(dirname "$(realpath "$0")")"
scripts="$here/../scripts"
state="$HOME/.local/state/velvet"

# Paquetes (paru resuelve repo + AUR; si no, pacman)
pkgs=(quickshell grim swappy wf-recorder wl-clipboard imagemagick brightnessctl ddcutil
      power-profiles-daemon gamemode hypridle hyprsunset
      libnotify curl libpulse procps-ng bash cliphist wtype
      ttf-jetbrains-mono noto-fonts-emoji)
step "paquetes"
if have paru; then paru -S --needed "${pkgs[@]}"; else sudo pacman -S --needed "${pkgs[@]}"; fi

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

# Scripts ejecutables
chmod +x "$scripts"/*.sh

# Modo inicial (lo leen velvet y Hyprland)
[ -f "$state/mode" ] || echo general > "$state/mode"

# Colores de terminal del modo GENERAL: foot.ini incluye foot-colors.ini y debe existir
# antes del primer arranque de velvet (luego velvet los regenera según el modo)
step "colores de terminal (foot + fastfetch)"
bash "$scripts/term.sh" e60012 0055ff ffe600

# Bloqueo por inactividad: hypridle.conf lo genera velvet (Ajustes → Energía)
if [ -e "$HOME/.config/hypr/hypridle.conf" ] || [ -d "$HOME/.config/hypr" ]; then
    step "hypridle (5 min bloquear · 10 min pantalla)"
    [ -e "$HOME/.config/hypr/hypridle.conf" ] || touch "$HOME/.config/hypr/hypridle.conf"
    sh "$scripts/idle.sh" 5 10 0 || true
    systemctl --user enable --now hypridle.service 2>/dev/null || true
else
    step "hypridle: falta ~/.config/hypr (stow hypr primero) — saltado"
fi

step "velvet instalado (cierra sesión si te ha añadido a i2c o gamemode)"
#!/usr/bin/env bash
# Instalación de velvet: lo que no resuelve stow. Idempotente.
# Refleja lo declarado en ../shell.toml (cuando exista el CLI, lo hará él).
set -euo pipefail

step() { printf '  \e[1;34m·\e[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Paquetes (paru resuelve repo + AUR; si no, pacman)
pkgs=(quickshell grim swappy wf-recorder wl-clipboard imagemagick brightnessctl ddcutil
      power-profiles-daemon libnotify curl libpulse procps-ng ttf-jetbrains-mono)
step "paquetes"
if have paru; then paru -S --needed "${pkgs[@]}"; else sudo pacman -S --needed "${pkgs[@]}"; fi

# Brillo de monitores externos (ddcutil)
step "módulo i2c-dev + grupo i2c"
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
sudo modprobe i2c-dev
getent group i2c >/dev/null || sudo groupadd i2c
id -nG "$USER" | grep -qw i2c || sudo usermod -aG i2c "$USER"

# Perfiles de energía (selector del menú de pausa)
step "power-profiles-daemon (sin TLP)"
systemctl list-unit-files tlp.service >/dev/null 2>&1 && sudo systemctl disable --now tlp.service 2>/dev/null || true
sudo systemctl enable --now power-profiles-daemon.service

# velvet pinta su propio fondo
step "hyprpaper desactivado"
systemctl --user disable --now hyprpaper.service 2>/dev/null || true
pkill -x hyprpaper 2>/dev/null || true

# Carpetas que usa
step "carpetas"
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings" "$HOME/.local/state/velvet"

# Scripts ejecutables
chmod +x "$(dirname "$(realpath "$0")")"/../scripts/*.sh

step "velvet instalado"
#!/usr/bin/env bash
# Desinstalación de velvet. No borra paquetes (pueden usarlos otros shells).
set -euo pipefail
state="$HOME/.local/state/velvet"

qs -c velvet kill 2>/dev/null || true
pkill -INT -x wf-recorder 2>/dev/null || true
pkill -f '^gamemoded -r' 2>/dev/null || true      # modo GAME
pkill -x hyprsunset 2>/dev/null || true           # luz nocturna

rm -rf "$state"

# foot.ini incluye este archivo: se deja vacío para que foot no dé error
mkdir -p "$state"
echo "# velvet desinstalado: borra la línea include= de foot.ini y esta carpeta" > "$state/foot-colors.ini"

cat <<'EOF'
velvet detenido. Queda a mano:
  · quitar 'qs -c velvet -d' del autostart (execs.lua) y sus atajos (keybinds.lua)
  · quitar la línea include= de foot.ini y luego ~/.local/state/velvet
  · hypridle sigue activo y su lock_cmd llama a velvet: cámbialo o desactívalo
    (systemctl --user disable --now hypridle)
  · Hyprland lee scheme/active.lua: sin el archivo de modo usa GENERAL
EOF
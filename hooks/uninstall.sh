#!/usr/bin/env bash
# Desinstalación de velvet (la llama `duran uninstall velvet`, que ya lo ha parado y quitado
# su parte de Hyprland). No borra paquetes ni tu ~/.config/hypr.
set -euo pipefail
state="$HOME/.local/state/velvet"

qs -c velvet kill 2>/dev/null || true
pkill -INT -x wf-recorder 2>/dev/null || true
pkill -f '^gamemoded -r' 2>/dev/null || true      # modo GAME
pkill -x hyprsunset 2>/dev/null || true           # luz nocturna

rm -rf "$state"

# Si foot.ini incluye foot-colors.ini, se deja vacío para que foot no dé error
if grep -qs 'velvet/foot-colors.ini' "$HOME/.config/foot/foot.ini"; then
    mkdir -p "$state"
    echo "# velvet desinstalado: borra la línea include= de foot.ini y esta carpeta" > "$state/foot-colors.ini"
fi

cat <<'EOF'
velvet desinstalado. Queda a mano (si quieres):
  · hypridle sigue activo y su lock_cmd llama a velvet:
      systemctl --user disable --now hypridle
  · la línea include= de ~/.config/foot/foot.ini y el fastfetch de fish_greeting
  · tus atajos siguen llamando a `duran ipc …`: funcionan con otro shell que tenga esas acciones
EOF

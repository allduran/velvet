#!/usr/bin/env bash
# Colores de terminal del modo activo (lo llama velvet al arrancar y al cambiar de modo).
#  - foot:      ~/.local/state/velvet/foot-colors.ini  (cursor + selección; foot.ini lo incluye)
#  - fastfetch: ~/.local/state/velvet/fastfetch.jsonc  (tu config.jsonc con el trío del modo)
# Uso: term.sh <hex1> <hex2> <hex3>      (sin #, p. ej. e60012 0055ff ffe600)
set -eu
c1=${1:-e60012}
c2=${2:-0055ff}
c3=${3:-ffe600}
state="$HOME/.local/state/velvet"
mkdir -p "$state"

rgb() { printf '38;2;%d;%d;%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }

# ── foot ──
cat > "$state/foot-colors.ini" <<EOF
# Generado por velvet según el modo. No editar.
[colors-dark]
cursor=0d0e12 $c1
selection-foreground=0d0e12
selection-background=$c3
EOF

# ── fastfetch ──
src="$HOME/.config/fastfetch/config.jsonc"
if [ -f "$src" ]; then
    r1=$(rgb "$c1"); r2=$(rgb "$c2"); r3=$(rgb "$c3")
    sed -e "s/{#bright_red}/{#1;$r1}/g; s/{#red}/{#$r1}/g; s/{#31}/{#$r1}/g" \
        -e "s/{#bright_blue}/{#1;$r2}/g; s/{#blue}/{#$r2}/g; s/{#34}/{#$r2}/g" \
        -e "s/{#bright_yellow}/{#1;$r3}/g; s/{#yellow}/{#$r3}/g; s/{#33}/{#$r3}/g" \
        -e "s/\"1\": \"red\"/\"1\": \"$r1\"/" \
        "$src" > "$state/fastfetch.jsonc"
fi
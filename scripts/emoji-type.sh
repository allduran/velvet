#!/usr/bin/env sh
# Escribe un emoji en la ventana activa.
# Los de un solo carácter van con wtype. Los compuestos (tono de piel, banderas, ZWJ, FE0F…)
# se pegan desde el portapapeles: wtype los manda carácter a carácter y apps web como
# WhatsApp los rompen. Después se devuelve al portapapeles lo que había.
e="$1"
n=$(printf %s "$e" | LC_ALL=C.UTF-8 wc -m)
[ "$n" -le 1 ] && exec wtype "$e"

# Guarda el portapapeles actual (con su tipo: texto, imagen…)
tmp=$(mktemp)
type=$(wl-paste -l 2>/dev/null | head -n1)
[ -n "$type" ] && wl-paste -n -t "$type" > "$tmp" 2>/dev/null

printf %s "$e" | wl-copy
sleep 0.1
class=$(hyprctl activewindow -j | grep -o '"class": *"[^"]*"' | cut -d'"' -f4)
case "$class" in
    foot | kitty | Alacritty | org.kde.konsole | com.mitchellh.ghostty)
        wtype -M ctrl -M shift v -m shift -m ctrl ;;   # terminales: Ctrl+Shift+V
    *)
        wtype -M ctrl v -m ctrl ;;
esac

# Devuelve lo que había (si había algo)
sleep 0.3
[ -n "$type" ] && wl-copy -t "$type" < "$tmp"
rm -f "$tmp"
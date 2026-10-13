#!/usr/bin/env bash
# capture.sh shot-full <salida>                  -> captura de un monitor entero
# capture.sh shot-crop <congelada.png> <WxH+X+Y> -> recorta la imagen congelada
# capture.sh rec-start <output:NOMBRE | "X,Y WxH"> <audio 0|1>
# capture.sh rec-stop
shots="$HOME/Pictures/Screenshots"
vids="$HOME/Videos/Recordings"
run="${XDG_RUNTIME_DIR:-/tmp}"
filef="$run/velvet-rec.file"
stamp() { date +%Y-%m-%d_%H-%M-%S; }

# Notificación con acciones (la pinta el propio shell)
notify() { # título cuerpo archivo etiqueta-principal
    act=$(notify-send -a Velvet -i "$3" -A primary="$4" -A open="ABRIR CARPETA" "$1" "$2")
    case "$act" in
    primary) if [ "$4" = EDITAR ]; then swappy -f "$3"; else xdg-open "$3"; fi ;;
    open) xdg-open "$(dirname "$3")" ;;
    esac
}

case "$1" in
shot-full)
    mkdir -p "$shots"
    f="$shots/captura_$(stamp).png"
    grim -o "$2" "$f" || exit 1
    wl-copy <"$f"
    notify "CAPTURA GUARDADA" "Copiada al portapapeles · $(basename "$f")" "$f" EDITAR
    ;;
shot-crop)
    mkdir -p "$shots"
    f="$shots/captura_$(stamp).png"
    magick "$2" -crop "$3" +repage "$f" || exit 1
    rm -f "$2"
    wl-copy <"$f"
    notify "CAPTURA GUARDADA" "Copiada al portapapeles · $(basename "$f")" "$f" EDITAR
    ;;
rec-start)
    pgrep -x wf-recorder >/dev/null && exit 0
    mkdir -p "$vids"
    f="$vids/grabacion_$(stamp).mp4"
    args=(-f "$f")
    if [[ "$2" == output:* ]]; then args+=(-o "${2#output:}"); else args+=(-g "$2"); fi
    [ "$3" = 1 ] && args+=(--audio="$(pactl get-default-sink).monitor")
    echo "$f" >"$filef"
    nohup wf-recorder "${args[@]}" >"$run/velvet-rec.log" 2>&1 &
    disown
    ;;
rec-stop)
    pgrep -x wf-recorder >/dev/null || exit 0
    f=$(cat "$filef" 2>/dev/null)
    rm -f "$filef"
    pkill -INT -x wf-recorder
    while pgrep -x wf-recorder >/dev/null; do sleep 0.1; done
    [ -n "$f" ] && notify "GRABACIÓN GUARDADA" "$(basename "$f") · ~/Videos/Recordings" "$f" REPRODUCIR
    ;;
esac

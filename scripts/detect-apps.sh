#!/usr/bin/env bash
# Pone en variables.lua las apps que ya usa el sistema (navegador, archivos, editor, audio).
# Lo llama hooks/install.sh al instalar la config de inicio. Se puede repetir sin problema.
# Uso: detect-apps.sh [ruta/a/variables.lua]
set -uo pipefail

vars="${1:-$HOME/.config/hypr/variables.lua}"
[ -f "$vars" ] || exit 0
have() { command -v "$1" >/dev/null 2>&1; }

# Comando de un .desktop (sin %U, %f…). Si es de terminal, se abre en foot.
exec_of() {
    local id="$1" d f cmd
    [ -n "$id" ] || return 1
    for d in "$HOME/.local/share/applications" /usr/local/share/applications /usr/share/applications \
             "$HOME/.local/share/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications; do
        f="$d/$id"
        [ -f "$f" ] || continue
        cmd=$(grep -m1 '^Exec=' "$f" | sed 's/^Exec=//; s/ *%[a-zA-Z]//g')
        [ -n "$cmd" ] || return 1
        grep -q '^Terminal=true' "$f" && cmd="foot -e $cmd"
        echo "$cmd"
        return 0
    done
    return 1
}

# Primer programa instalado de la lista
first_of() {
    local c
    for c in "$@"; do have "${c%% *}" && { echo "$c"; return 0; }; done
    return 1
}

# App por defecto para un tipo MIME (la que eligió el usuario en su escritorio)
default_for() {
    have xdg-mime || return 1
    exec_of "$(xdg-mime query default "$1" 2>/dev/null)"
}

# Cambia el valor de `clave = "…"` en variables.lua
set_var() {
    local key="$1" val="$2" tmp
    [ -n "$val" ] || return 0
    val=${val//\\/\\\\}
    val=${val//\"/\\\"}
    tmp=$(mktemp)
    KEY="$key" VAL="$val" awk '
        BEGIN { k = ENVIRON["KEY"]; v = ENVIRON["VAL"] }
        !done && $0 ~ "^[ \t]*" k "[ \t]*=" {
            i = index($0, "\"")
            if (i) {
                rest = substr($0, i + 1); j = index(rest, "\"")
                if (j) { $0 = substr($0, 1, i) v substr(rest, j); done = 1 }
            }
        }
        { print }' "$vars" > "$tmp" && cat "$tmp" > "$vars"
    rm -f "$tmp"
    printf '      %-13s %s\n' "$key" "$2"
}

browser=$( (have xdg-settings && exec_of "$(xdg-settings get default-web-browser 2>/dev/null)") \
        || default_for x-scheme-handler/https \
        || first_of firefox zen-browser brave chromium google-chrome-stable vivaldi-stable)
files=$(default_for inode/directory || first_of dolphin nautilus thunar nemo pcmanfm-qt pcmanfm)
editor=$(default_for text/plain || first_of kate kwrite code codium gnome-text-editor mousepad)
audio=$(first_of pwvucontrol pavucontrol "systemsettings kcm_pulseaudio")

set_var browser "$browser"
set_var fileExplorer "$files"
set_var editor "$editor"
set_var audioSettings "$audio"
exit 0

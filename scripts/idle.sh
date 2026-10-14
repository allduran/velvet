#!/usr/bin/env sh
# Regenera hypridle.conf con los tiempos de velvet (Ajustes → Energía, por modo) y reinicia hypridle.
# Escribe a través del enlace de stow, así el cambio queda en ~/dotfiles.
# Uso: idle.sh <bloquear_min> <apagar_pantalla_min> <suspender_min>   (0 = nunca)
lock=${1:-5}
dpms=${2:-10}
sleep=${3:-0}
conf=$(readlink -f "$HOME/.config/hypr/hypridle.conf")

{
    cat <<EOF
# Generado por velvet (Ajustes → Energía). Los cambios a mano se pisan.
general {
    lock_cmd = pidof qs >/dev/null && qs -c velvet ipc call lock lock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}
EOF
    if [ "$lock" -gt 0 ]; then
        cat <<EOF

listener {
    timeout = $((lock * 60))
    on-timeout = loginctl lock-session
}
EOF
    fi
    if [ "$dpms" -gt 0 ]; then
        cat <<EOF

listener {
    timeout = $((dpms * 60))
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF
    fi
    if [ "$sleep" -gt 0 ]; then
        cat <<EOF

listener {
    timeout = $((sleep * 60))
    on-timeout = systemctl suspend
}
EOF
    fi
} > "$conf"

systemctl --user restart hypridle.service

#!/usr/bin/env bash
# Instala (o pone al día) la config de Hyprland de velvet en ~/.config/hypr.
# Si ya hay una config, avisa, la guarda en ~/.config/hypr.antes-de-velvet-<fecha> y la sustituye
# (README → «Tu config de Hyprland anterior» explica cómo recuperarla).
#
# No toca nada si:
#   · ~/.config/hypr es un enlace o un repo git (dotfiles con stow), o
#   · VELVET_KEEP_HYPR=1, o
#   · la config ya es la de esta versión de velvet.
#
# Uso: hypr-starter.sh            (pregunta si hay terminal)
#      hypr-starter.sh --si       (sin preguntar)
set -uo pipefail

root="$(dirname "$(realpath "$0")")/.."
starter="$root/hypr/starter"
hypr="$HOME/.config/hypr"
state="$HOME/.local/state/velvet"
step() { printf '  \e[1;34m·\e[0m %s\n' "$*"; }
warn() { printf '  \e[1;33m!\e[0m %s\n' "$*"; }

mkdir -p "$state"
hash=$(cd "$starter" && find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -c1-16)

# Config gestionada a mano (dotfiles con stow o git): nunca se toca
if [ -L "$hypr" ] || [ -L "$hypr/hyprland.lua" ] || [ -L "$hypr/hyprland.conf" ] || [ -d "$hypr/.git" ] || [ -n "${VELVET_KEEP_HYPR:-}" ]; then
    step "Hyprland: config propia (dotfiles o VELVET_KEEP_HYPR) — no se toca"
    exit 0
fi

existing=false
if [ -e "$hypr/hyprland.lua" ] || [ -e "$hypr/hyprland.conf" ]; then existing=true; fi
was_velvet=false
[ -f "$state/starter.sha" ] && was_velvet=true

if $existing && [ "$(cat "$state/starter.sha" 2>/dev/null)" = "$hash" ]; then
    step "Hyprland: la config de velvet ya está al día"
    exit 0
fi

backup=""
if $existing; then
    backup="$HOME/.config/hypr.antes-de-velvet-$(date +%Y%m%d-%H%M%S)"
    if $was_velvet; then
        warn "velvet trae una config de Hyprland nueva y va a SUSTITUIR la tuya (~/.config/hypr)."
    else
        warn "velvet va a SUSTITUIR tu config de Hyprland (~/.config/hypr) por la suya."
    fi
    warn "La actual se guarda en ${backup/#$HOME/\~} (README → «Tu config de Hyprland anterior»)."
    if [ -t 0 ] && [ "${1:-}" != "--si" ]; then
        read -r -p "    ¿Seguir? [S/n] " ans
        case "${ans,,}" in
            n | no)
                step "Hyprland: no se toca. Para integrar velvet a mano, mira el README."
                exit 0
                ;;
        esac
    fi
    cp -a "$hypr" "$backup"
    find "$hypr" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
else
    mkdir -p "$hypr"
fi

cp -r "$starter/." "$hypr/"

# Lo que no es de la config sino de este equipo o de velvet se conserva
if [ -n "$backup" ]; then
    keep=(shell.lua hypridle.conf)                                  # enlace de duran y bloqueo por inactividad
    $was_velvet && keep+=(monitors.lua toggles.json hyprsunset.conf) # pantallas y workspaces que ya tenías con velvet
    for f in "${keep[@]}"; do
        if [ -e "$backup/$f" ] || [ -L "$backup/$f" ]; then
            rm -f "$hypr/$f"
            cp -a "$backup/$f" "$hypr/$f"
        fi
    done
fi

step "apps de tu sistema → variables.lua"
bash "$root/scripts/detect-apps.sh" "$hypr/variables.lua" || true
bash "$root/scripts/detect-kde.sh" "$hypr" || true

echo "$hash" > "$state/starter.sha"
step "Hyprland: config de velvet instalada"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then hyprctl reload >/dev/null 2>&1; fi
exit 0

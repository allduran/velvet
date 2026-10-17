#!/usr/bin/env bash
# Tras `duran update velvet`: pone al día la config de Hyprland si la nueva versión la cambia.
# (Avisa y guarda la anterior; ver duran hypr init.)
set -uo pipefail

root="$(dirname "$(realpath "$0")")/.."
chmod +x "$root/scripts/"*.sh 2>/dev/null
duran hypr init

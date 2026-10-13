#!/usr/bin/env bash
# Desinstalación de velvet. No borra paquetes (pueden usarlos otros shells).
set -euo pipefail
qs -c velvet kill 2>/dev/null || true
pkill -INT -x wf-recorder 2>/dev/null || true
rm -rf "$HOME/.local/state/velvet"
echo "velvet detenido. Recuerda quitar 'qs -c velvet -d' del autostart y sus atajos."
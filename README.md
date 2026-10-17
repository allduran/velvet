# velvet

Shell de [Quickshell](https://quickshell.org) para Hyprland con estética Persona (P3 · P4 · P5)
y **modos** — GENERAL, DEV, ART, GAME y los que crees tú — que cambian colores, fondo, favoritos del lanzador
y la configuración del sistema de golpe.

## Qué incluye

- **Barra, lanzador, notificaciones, OSD** de volumen/brillo, menú de pausa (sesión) y pantalla de bloqueo.
- **Selector de modo** (`SUPER + TAB`). Cada modo aplica:
  - paleta y fondo propios, y favoritos del lanzador;
  - perfil de energía, bloqueo/apagado de pantalla por inactividad, No molestar, luz nocturna y gamemode;
  - huecos, animaciones, blur y VRR de Hyprland;
  - colores de la terminal (foot) y de fastfetch;
  - apps que se abren al entrar, cada una en su workspace.
  - **Administrar modos** (`SUPER + TAB` → `M`): oculta los de serie o crea los tuyos (hasta 6 en el selector), con estilo PERSONAS, PERSONA 3, PERSONA 4 o PERSONA 5 y sus propios ajustes.
- **Ajustes** (`SUPER + I`): todo lo anterior por modo, sin tocar archivos.
- Selector de fondos, capturas y grabación, portapapeles (cliphist) y selector de emojis.

## Requisitos

- Arch / CachyOS (los paquetes se instalan con `pacman`/`paru`).
- Hyprland con **config en Lua**.
- [duran](https://github.com/allduran/duran), que instala y arranca el shell.

> ¿Vienes de KDE u otro escritorio? Instala Hyprland (`sudo pacman -S hyprland`) y elige la sesión
> «Hyprland» en la pantalla de inicio. Tu escritorio actual no se toca.

## Instalación

```sh
duran install allduran/velvet --switch
```

duran instala los paquetes de `shell.toml` y ejecuta `hooks/install.sh`, que:

- pone **su config de Hyprland** (`hypr/starter`) en `~/.config/hypr`. Si ya tenías una, **te avisa,
  la guarda y la sustituye** (ver [Tu config de Hyprland anterior](#tu-config-de-hyprland-anterior));
- activa power-profiles-daemon, hypridle, i2c (brillo de monitores externos) y gamemode;
- crea las carpetas y el estado de velvet.

Cierra sesión y entra en Hyprland. Si te añadió a los grupos `i2c` o `gamemode`, hace falta para que cuenten.

Con `duran update velvet` pasa lo mismo cuando una versión nueva cambia la config de Hyprland:
avisa, guarda la tuya y pone la nueva (tus pantallas y tus workspaces especiales se conservan).

### Tu config de Hyprland anterior

Cada vez que velvet sustituye `~/.config/hypr`, guarda la que había en
`~/.config/hypr.antes-de-velvet-<fecha>`. Para verlas y volver a una:

```sh
ls -d ~/.config/hypr.antes-de-velvet-*          # copias guardadas, la última al final
duran stop
mv ~/.config/hypr ~/.config/hypr.velvet
mv ~/.config/hypr.antes-de-velvet-<fecha> ~/.config/hypr
hyprctl reload
```

Para que velvet **no toque nunca** tu config, responde `n` cuando pregunte, o instala y actualiza así:

```sh
VELVET_KEEP_HYPR=1 duran install allduran/velvet
VELVET_KEEP_HYPR=1 duran update velvet
```

Si `~/.config/hypr` es un enlace o un repo git (dotfiles con stow), velvet tampoco lo toca.

### Ya tengo mi config de Hyprland (y quiero conservarla)

Para integrar velvet a mano:

1. **Tema por modo:** velvet trae `hypr/shell.lua`, que duran enlaza en `~/.config/hypr/shell.lua`.
   Cárgalo desde tu config y usa sus valores (`accent`, `inactive`, `gapsIn`, `gapsOut`, `animations`, `blur`, `vrr`…):
   ```lua
   local ok, shell = pcall(require, "shell")
   local t = ok and shell.theme or {}
   ```
   `hypr/starter/scheme/active.lua` es un ejemplo completo con valores por defecto.
2. **Arranque:** `hl.exec_cmd("duran start")` y el historial del portapapeles
   (`wl-paste --type text --watch cliphist store`, ídem con `image`).
3. **Atajos:** llama a `duran ipc <acción>` (lista completa: `duran ipc`). Ejemplos en `hypr/starter/hyprland/keybinds.lua`.
   Las apps de Ajustes → Atajos: `duran ipc app <terminal|browser|editor|files|audio>`.
   El teclado de Ajustes: usa `kbLayout` y `kbOptions` del tema (ejemplo en `hypr/starter/hyprland/input.lua`).
4. Quita otros fondos (hyprpaper) y otras luces nocturnas (gammastep, wlsunset): velvet ya lo hace.

## Atajos (config de inicio)

| Atajo | Acción |
|---|---|
| `SUPER` | Lanzador |
| `SUPER + TAB` | Selector de modo |
| `SUPER + I` | Ajustes |
| `SUPER + SHIFT + W` | Selector de fondos |
| `SUPER + L` | Bloquear |
| `CTRL + ALT + Supr` | Menú de sesión |
| `SUPER + V` / `SUPER + .` | Portapapeles / emojis |
| `Impr` · `SUPER + SHIFT + S` | Captura de pantalla / de región |
| `CTRL + ALT + R` | Grabar pantalla |
| `SUPER + T` · `SUPER + W` · `SUPER + E` | Terminal · navegador · archivos |
| `SUPER + Q` | Cerrar ventana |

Las apps (terminal, navegador, editor…), el cursor y el resto de atajos están en `~/.config/hypr/variables.lua`.
Tus monitores, en `~/.config/hypr/monitors.lua` (o con `nwg-displays`).

## Fondos

velvet usa los de `~/Pictures/Wallpapers` con este nombre:

```
wallpaper-<red|blue|yellow>-<n>.<jpg|jpeg|png>     p. ej. wallpaper-red-1.png
```

GENERAL muestra todos; DEV solo `blue`, ART solo `yellow` y GAME solo `red`.
Sin fondos, velvet pinta unas franjas con los colores del modo.

## Terminal (opcional)

Para que foot y fastfetch sigan los colores del modo:

```ini
# primera línea de ~/.config/foot/foot.ini
include=~/.local/state/velvet/foot-colors.ini
```

```fish
# fish
function fish_greeting; fastfetch -c ~/.local/state/velvet/fastfetch.jsonc; end
```

## Desinstalar

```sh
duran uninstall velvet
```

Para el shell, ejecuta `hooks/uninstall.sh` y quita su parte de Hyprland. Tu `~/.config/hypr` se queda.

## Licencia

[GPL-3.0](LICENSE). Las fuentes de `assets/fonts` (Bebas Neue, Montserrat) mantienen su licencia SIL OFL.

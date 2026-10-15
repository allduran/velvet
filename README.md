# velvet

Shell de [Quickshell](https://quickshell.org) para Hyprland con estética Persona (P3 · P4 · P5)
y cuatro **modos** — GENERAL, DEV, ART y GAME — que cambian colores, fondo, favoritos del lanzador
y la configuración del sistema de golpe.

## Qué incluye

- **Barra, lanzador, notificaciones, OSD** de volumen/brillo, menú de pausa (sesión) y pantalla de bloqueo.
- **Selector de modo** (`SUPER + TAB`). Cada modo aplica:
  - paleta y fondo propios, y favoritos del lanzador;
  - perfil de energía, bloqueo/apagado de pantalla por inactividad, No molestar, luz nocturna y gamemode;
  - huecos, animaciones, blur y VRR de Hyprland;
  - colores de la terminal (foot) y de fastfetch;
  - apps que se abren al entrar, cada una en su workspace.
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

- si **no tienes config de Hyprland**, copia la de inicio (`hypr/starter`) a `~/.config/hypr`;
- activa power-profiles-daemon, hypridle, i2c (brillo de monitores externos) y gamemode;
- crea las carpetas y el estado de velvet.

Cierra sesión y entra en Hyprland. Si te añadió a los grupos `i2c` o `gamemode`, hace falta para que cuenten.

### Ya tengo mi config de Hyprland

El hook no la toca. Para integrar velvet:

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

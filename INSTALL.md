# Instalar velvet en CachyOS (viniendo de KDE)

Tu KDE no se toca: Hyprland se instala como una **sesión aparte** y eliges cuál usar al iniciar sesión.

## 1. Instalar Hyprland

Desde KDE, en una terminal:

```fish
sudo pacman -S --needed hyprland git
```

## 2. Instalar duran

duran es el programa que instala y arranca velvet.

```fish
cd /tmp
curl -LO https://github.com/allduran/duran/releases/download/v0.2.1/duran-v0.2.1-linux-x64.tar.gz
mkdir -p duran; and tar -xzf duran-v0.2.1-linux-x64.tar.gz -C duran
install -Dm755 duran/duran ~/.local/bin/duran
mkdir -p ~/.config/fish/completions; and cp duran/duran.fish ~/.config/fish/completions/
```

### Comprobar

```fish
fish_add_path ~/.local/bin
duran --version
```

Tiene que salir un número de versión (p. ej. `0.2.1`).

## 3. Instalar velvet

```fish
duran install allduran/velvet
```

- Te pedirá la contraseña y confirmar paquetes: acepta.
- Prepara Hyprland para velvet y usa las apps que ya tienes (navegador, archivos, editor).

## 4. Entrar en Hyprland

1. Cierra sesión.
2. En la pantalla de inicio, elige la sesión **Hyprland** (selector de sesión) y entra.
3. velvet arranca solo.

## 5. Atajos básicos

| Atajo | Qué hace |
|---|---|
| `SUPER` | Lanzador de apps |
| `SUPER + T` | Terminal |
| `SUPER + TAB` | Cambiar de modo (GENERAL · DEV · ART · GAME) |
| `SUPER + I` | Ajustes (energía, apps por modo, favoritos…) |
| `SUPER + SHIFT + W` | Fondos |
| `SUPER + Q` | Cerrar ventana |
| `SUPER + L` | Bloquear |
| `CTRL + ALT + Supr` | Apagar · reiniciar · cerrar sesión |

## 6. Pantallas y fondos

- **Una pantalla:** no hay que hacer nada.
- **Varias pantallas:** si salen mal colocadas, pulsa `SUPER`, abre **nwg-displays**,
  arrástralas a su sitio y pulsa **Apply**.
- **Fondos:** guárdalos en la carpeta `Pictures/Wallpapers` con estos nombres:
  `wallpaper-red-1.png`, `wallpaper-blue-1.jpg`, `wallpaper-yellow-1.png`…
  (el color decide en qué modo salen). Luego elígelos con `SUPER + SHIFT + W`.

## 7. Si algo falla

```fish
duran status            # ¿está velvet corriendo?
hyprctl configerrors    # errores de la config de Hyprland
qs log -c velvet        # log de velvet
```

## Volver a KDE

Cierra sesión y elige **Plasma** en la pantalla de inicio.

## Quitarlo todo (opcional)

```fish
duran uninstall velvet
sudo pacman -Rns hyprland
rm -r ~/.config/hypr
```

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"

// Selector de emojis flotante.  qs -c velvet ipc call emoji toggle
// Enter escribe el emoji en la ventana activa; Shift+Enter solo lo copia.
// Ctrl+Enter (o Ctrl+clic / clic derecho) lo deja EN COLA: el siguiente Enter escribe la cola + ese emoji.
Scope {
    id: root

    property string screenName: ""      // "" = cerrado
    function close() {
        screenName = "";
    }

    property var all: []                // [{ e, n, g, k, s }]  s = texto de búsqueda normalizado
    // Minúsculas y sin tildes (sin String.normalize, que el motor de QML no siempre trae)
    function norm(t) {
        return t.toLowerCase().replace(/[áàäâã]/g, "a").replace(/[éèëê]/g, "e").replace(/[íìïî]/g, "i").replace(/[óòöôõ]/g, "o").replace(/[úùüû]/g, "u").replace(/ñ/g, "n").replace(/ç/g, "c");
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void {
            root.screenName = root.screenName !== "" ? "" : (Hyprland.focusedMonitor?.name ?? "");
        }
    }

    // Lista de emojis (nombres en español, de emojibase)
    FileView {
        path: Quickshell.shellDir + "/assets/emoji.json"
        onLoaded: {
            try {
                const list = JSON.parse(text());
                for (const x of list)
                    x.s = root.norm(x.n + " " + x.k);
                root.all = list;
                console.log("velvet emoji: " + list.length + " cargados");
            } catch (e) {
                console.warn("velvet emoji: no se pudo leer assets/emoji.json → " + e);
            }
        }
    }

    // Recientes
    FileView {
        id: recentFile
        path: Quickshell.env("HOME") + "/.local/state/velvet/emoji.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: recent
            property var list: []
        }
    }
    function remember(e) {
        recent.list = [e].concat((recent.list ?? []).filter(x => x !== e)).slice(0, 16);
    }

    // Escribe (o solo copia) uno o varios emojis de golpe
    function send(list, copyOnly) {
        const text = list.map(x => x.e).join("");
        for (const x of list)
            remember(x.e);
        close();
        if (copyOnly) {
            Quickshell.execDetached(["wl-copy", text]);
        } else {
            typeT.text = text;
            typeT.restart();
        }
    }
    // Espera a que vuelva el foco a la ventana antes de pegar
    Timer {
        id: typeT
        property string text: ""
        interval: 150
        // Se pega desde el portapapeles (escribirlo con wtype rompe los emojis compuestos en apps web).
        // En terminales el atajo de pegar es Ctrl+Shift+V.
        onTriggered: Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy || exit; sleep 0.1; " + "case \"$(hyprctl activewindow -j | jq -r .class)\" in " + "foot|kitty|Alacritty|org.wezfurlong.wezterm|com.mitchellh.ghostty|org.kde.konsole) wtype -M ctrl -M shift v -m shift -m ctrl ;; " + "*) wtype -M ctrl v -m ctrl ;; esac", "sh", text])
    }

    readonly property var cats: [["recent", "RECIENTES"], [0, "CARAS"], [1, "GENTE"], [3, "NATURALEZA"], [4, "COMIDA"], [6, "ACTIVIDADES"], [5, "VIAJES"], [7, "OBJETOS"], [8, "SÍMBOLOS"], [9, "BANDERAS"]]

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.screenName === modelData.name
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velvet-emoji"
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            // Colores del modo activo
            readonly property color c1: Theme.accent
            readonly property color c2: Theme.accent2
            readonly property color c3: Theme.accent3

            property var cat: "recent"
            property string query: ""
            readonly property var items: {
                if (query) {
                    const q = root.norm(query);
                    return root.all.filter(x => x.s.includes(q)).slice(0, 300);
                }
                if (cat === "recent") {
                    const r = (recent.list ?? []).map(e => root.all.find(x => x.e === e)).filter(x => x);
                    return r.length ? r : root.all.filter(x => x.g === 0);
                }
                return root.all.filter(x => x.g === cat);
            }
            property int sel: 0
            readonly property var current: items.length ? items[Math.min(sel, items.length - 1)] : null

            // Cola para escribir varios seguidos
            property var tray: []
            function queue(item) {
                if (item && tray.length < 24)
                    tray = tray.concat([item]);
            }
            function unqueue(i) {
                const t = tray.slice();
                t.splice(i ?? t.length - 1, 1);
                tray = t;
            }
            // Escribe la cola + el emoji indicado (si lo hay)
            function commit(item, copyOnly) {
                const list = item ? tray.concat([item]) : tray;
                if (list.length)
                    root.send(list, copyOnly);
            }

            onVisibleChanged: if (visible) {
                search.text = "";
                cat = "recent";
                sel = 0;
                tray = [];
                search.input.forceActiveFocus();
            }
            function nextCat(d) {
                const i = root.cats.findIndex(c => c[0] === cat);
                cat = root.cats[(i + d + root.cats.length) % root.cats.length][0];
                search.text = "";
                sel = 0;
            }

            // ── Velo casi opaco + trama de puntos + franja ──
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha("#0A0A0E", 0.86)
            }
            Canvas {
                id: dots
                anchors.fill: parent
                property color dot: Qt.alpha(win.c1, 0.22)
                onDotChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = dot;
                    ctx.beginPath();
                    for (let y = 7; y < height; y += 14)
                        for (let x = 7; x < width; x += 14) {
                            ctx.moveTo(x + 1.5, y);
                            ctx.arc(x, y, 1.5, 0, 2 * Math.PI);
                        }
                    ctx.fill();
                }
            }
            Rectangle {
                x: -parent.width * 0.2
                y: parent.height * 0.72
                width: parent.width * 1.4
                height: 110
                rotation: -8
                color: win.c1
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            // ── Panel ──
            Item {
                id: stage
                width: 1100
                height: 720
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 20
                MouseArea {
                    anchors.fill: parent
                }

                // Sombra dura y panel macizo con la esquina inferior derecha cortada
                Shape {
                    x: 14
                    y: 14
                    width: stage.width
                    height: stage.height
                    ShapePath {
                        fillColor: win.c2
                        strokeColor: "transparent"
                        PathPolyline {
                            path: [Qt.point(0, 0), Qt.point(1100, 0), Qt.point(1100, 662), Qt.point(1056, 720), Qt.point(0, 720), Qt.point(0, 0)]
                        }
                    }
                }
                Shape {
                    anchors.fill: parent
                    ShapePath {
                        fillColor: Theme.surface
                        strokeColor: win.c3
                        strokeWidth: 2
                        PathPolyline {
                            path: [Qt.point(0, 0), Qt.point(1100, 0), Qt.point(1100, 662), Qt.point(1056, 720), Qt.point(0, 720), Qt.point(0, 0)]
                        }
                    }
                }

                // Título recortado que se sale del panel
                Rectangle {
                    x: -18 + 8
                    y: -46 + 8
                    width: titleT.implicitWidth + 36
                    height: titleT.implicitHeight
                    rotation: -3
                    color: win.c1
                }
                Rectangle {
                    x: -18
                    y: -46
                    width: titleT.implicitWidth + 36
                    height: titleT.implicitHeight
                    rotation: -3
                    color: Theme.paper
                    Text {
                        id: titleT
                        anchors.centerIn: parent
                        text: "EMOJIS"
                        color: Theme.ink
                        font.family: "Bebas Neue"
                        font.pixelSize: 96
                        font.letterSpacing: 6
                    }
                }
                Text {
                    x: 300
                    y: 52
                    text: "// " + (win.query ? "BÚSQUEDA" : root.cats.find(c => c[0] === win.cat)[1]) + " · " + win.items.length
                    color: win.c3
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: Font.ExtraBold
                    font.letterSpacing: 2
                }

                // Buscador (recibe todas las teclas)
                SearchBox {
                    id: search
                    anchors.right: parent.right
                    anchors.rightMargin: 34
                    y: 30
                    width: 360
                    accent: win.c1
                    placeholder: "fuego, corazón, gato…"
                    onTextChanged: {
                        win.query = text;
                        win.sel = 0;
                    }
                    onKeyPressed: event => {
                        const shift = event.modifiers & Qt.ShiftModifier;
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        switch (event.key) {
                        case Qt.Key_Escape:
                            root.close();
                            break;
                        case Qt.Key_Right:
                            win.sel = Math.min(win.items.length - 1, win.sel + 1);
                            break;
                        case Qt.Key_Left:
                            win.sel = Math.max(0, win.sel - 1);
                            break;
                        case Qt.Key_Down:
                            win.sel = Math.min(win.items.length - 1, win.sel + 10);
                            break;
                        case Qt.Key_Up:
                            win.sel = Math.max(0, win.sel - 10);
                            break;
                        case Qt.Key_Tab:
                            win.nextCat(1);
                            break;
                        case Qt.Key_Backtab:
                            win.nextCat(-1);
                            break;
                        case Qt.Key_Backspace:
                            if (!ctrl || !win.tray.length)
                                return;                 // borrar en el buscador
                            win.unqueue();
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (ctrl)
                                win.queue(win.current);
                            else
                                win.commit(win.current, shift);
                            break;
                        default:
                            return;
                        }
                        event.accepted = true;
                    }
                }

                // Categorías: pestañas sobre una línea; la activa es un recorte de papel
                Row {
                    x: 34
                    y: 110
                    height: 40
                    spacing: 4
                    Repeater {
                        model: root.cats
                        delegate: SkewChip {
                            required property var modelData
                            readonly property bool on: win.cat === modelData[0] && !win.query
                            anchors.verticalCenter: parent.verticalCenter
                            label: modelData[1]
                            fill: on ? Theme.paper : "transparent"
                            fg: on ? Theme.ink : Qt.alpha(Theme.paper, 0.75)
                            shadow: on ? win.c1 : "transparent"
                            rotation: on ? -2 : 0
                            size: 19
                            padding: 12
                            height: 32
                            onClicked: {
                                win.cat = modelData[0];
                                search.text = "";
                                win.sel = 0;
                            }
                        }
                    }
                }
                Rectangle {
                    x: 34
                    y: 150
                    width: stage.width - 68
                    height: 1
                    color: Qt.alpha(Theme.paper, 0.18)
                }

                // Rejilla: cada emoji en un recorte de papel
                GridView {
                    id: grid
                    x: 34
                    y: 168
                    width: 690
                    height: 480
                    clip: true
                    cellWidth: 69
                    cellHeight: 62
                    model: win.items
                    currentIndex: win.sel
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                    delegate: Item {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool on: index === win.sel
                        width: 69
                        height: 62
                        z: on ? 2 : 1
                        Item {
                            x: 4
                            y: 4
                            width: 61
                            height: 54
                            rotation: tile.on ? 0 : [-1.5, 1, -0.5, 1.5, -1, 0.5, -1.2, 0.8][tile.index % 8]
                            scale: tile.on ? 1.12 : 1
                            Behavior on scale {
                                enabled: Config.animations
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                            // Sombra
                            Rectangle {
                                x: tile.on ? 4 : 2
                                y: tile.on ? 4 : 2
                                width: parent.width
                                height: parent.height
                                color: tile.on ? win.c2 : Qt.alpha("#000000", 0.55)
                            }
                            // Papel (el elegido: color del modo con borde negro)
                            Rectangle {
                                visible: tile.on
                                anchors.fill: parent
                                anchors.margins: -3
                                color: Theme.ink
                            }
                            Cut {
                                anchors.fill: parent
                                seed: tile.index
                                fill: tile.on ? win.c1 : Theme.paper
                            }
                            Text {
                                anchors.centerIn: parent
                                text: tile.modelData.e
                                font.pixelSize: 29
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.sel = tile.index
                            // Clic: escribe (con la cola) · Ctrl+clic o clic derecho: a la cola
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton || (mouse.modifiers & Qt.ControlModifier))
                                    win.queue(tile.modelData);
                                else
                                    win.commit(tile.modelData, mouse.modifiers & Qt.ShiftModifier);
                            }
                        }
                    }
                }

                // Detalle: tarjeta de papel
                Item {
                    x: 760
                    y: 168
                    width: 306
                    height: 300
                    rotation: 1.5
                    Cut {
                        x: 10
                        y: 10
                        width: 296
                        height: 290
                        seed: 1
                        fill: win.c1
                    }
                    Cut {
                        width: 296
                        height: 290
                        seed: 1
                        fill: Theme.paper
                    }
                    Column {
                        x: 0
                        width: 296
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -5
                        spacing: 6
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: anT.implicitWidth + 16
                            height: anT.implicitHeight
                            color: Theme.ink
                            Text {
                                id: anT
                                anchors.centerIn: parent
                                text: "ANÁLISIS"
                                color: Theme.paper
                                font.family: "Bebas Neue"
                                font.pixelSize: 15
                                font.letterSpacing: 3
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.current?.e ?? ""
                            font.pixelSize: 104
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 260
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: (win.current?.n ?? "").toUpperCase()
                            color: Theme.ink
                            font.family: "Montserrat"
                            font.pixelSize: 15
                            font.weight: Font.Black
                            font.italic: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.current ? [...win.current.e].map(c => "U+" + c.codePointAt(0).toString(16).toUpperCase()).join(" ") : ""
                            color: Theme.on(win.c1) === Theme.ink ? Qt.darker(win.c1, 1.8) : win.c1
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: Font.ExtraBold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            readonly property int parts: win.current ? [...win.current.e].length : 0
                            text: parts > 1 ? parts + " CARACTERES · SE PEGA ENTERO" : "1 CARÁCTER"
                            color: "#5A5D6E"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.weight: Font.ExtraBold
                            font.letterSpacing: 1.5
                        }
                    }
                }

                // En cola (si hay) o recientes
                Column {
                    x: 760
                    y: 492
                    width: 306
                    spacing: 8
                    Row {
                        spacing: 10
                        SkewChip {
                            label: win.tray.length ? "EN COLA · " + win.tray.length : "RECIENTES"
                            fill: Theme.paper
                            fg: Theme.ink
                            shadow: win.c1
                            size: 20
                        }
                        Text {
                            visible: win.tray.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "ENTER ESCRIBE TODO · CTRL+⌫ QUITA"
                            color: win.c3
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.weight: Font.ExtraBold
                            font.letterSpacing: 1
                        }
                    }
                    Flow {
                        width: parent.width
                        spacing: 5
                        Repeater {
                            // Con cola: sus emojis (clic = quitar). Sin cola: recientes (clic = escribir)
                            model: win.tray.length ? win.tray.map(x => x.e) : (recent.list ?? []).slice(0, 16)
                            delegate: Item {
                                id: rc
                                required property string modelData
                                required property int index
                                width: 34
                                height: 34
                                Cut {
                                    anchors.fill: parent
                                    seed: rc.index
                                    fill: Theme.paper
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: rc.modelData
                                    font.pixelSize: 20
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (win.tray.length) {
                                            win.unqueue(rc.index);
                                            return;
                                        }
                                        const it = root.all.find(x => x.e === rc.modelData);
                                        if (it)
                                            win.commit(it, false);
                                    }
                                }
                            }
                        }
                    }
                }

                // Teclas
                Text {
                    x: 34
                    y: stage.height - 18 - height
                    textFormat: Text.StyledText
                    readonly property string k: "<b><font color='" + win.c3 + "'>"
                    text: k + "← ↑ → ↓</font></b> ELEGIR · " + k + "TAB</font></b> CATEGORÍA · " + k + "ENTER</font></b> ESCRIBIR · " + k + "CTRL+ENTER</font></b> A LA COLA · " + k + "SHIFT+ENTER</font></b> COPIAR · " + k + "ESC</font></b> CERRAR"
                    color: Qt.alpha(Theme.paper, 0.8)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                }
            }
        }
    }
}

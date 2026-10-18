import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"

// Selector de emojis flotante.  qs -c velvet ipc call emoji toggle
// Enter escribe el emoji en la ventana activa (wtype); Shift+Enter solo lo copia.
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

    function insert(item) {
        remember(item.e);
        close();
        typeT.text = item.e;
        typeT.restart();
    }
    function copy(item) {
        remember(item.e);
        Quickshell.execDetached(["wl-copy", item.e]);
        close();
    }
    // Espera a que vuelva el foco a la ventana antes de escribir
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

            readonly property color tint: Theme.accent3

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

            onVisibleChanged: if (visible) {
                search.text = "";
                cat = "recent";
                sel = 0;
                search.input.forceActiveFocus();
            }

            function nextCat(d) {
                const i = root.cats.findIndex(c => c[0] === cat);
                cat = root.cats[(i + d + root.cats.length) % root.cats.length][0];
                search.text = "";
                sel = 0;
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Item {
                width: 1000
                height: 700
                anchors.centerIn: parent
                MouseArea {
                    anchors.fill: parent
                }

                // Cabecera
                Row {
                    spacing: 18
                    BigTitle {
                        text: "EMOJIS"
                        shadow: win.tint
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        width: hT.implicitWidth + 20
                        height: 22
                        color: Qt.alpha(Theme.ink, 0.85)
                        Text {
                            id: hT
                            anchors.centerIn: parent
                            text: "ENTER ESCRIBE · SHIFT+ENTER COPIA"
                            color: Theme.telemetry
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 2
                        }
                    }
                }
                SearchBox {
                    id: search
                    anchors.right: parent.right
                    y: 20
                    width: 360
                    accent: Theme.ink
                    placeholder: "fuego, corazón, gato…"
                    onTextChanged: {
                        win.query = text;
                        win.sel = 0;
                    }
                    onKeyPressed: event => {
                        const shift = event.modifiers & Qt.ShiftModifier;
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
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (win.current)
                                shift ? root.copy(win.current) : root.insert(win.current);
                            break;
                        default:
                            return;
                        }
                        event.accepted = true;
                    }
                }

                // Categorías
                Flow {
                    y: 100
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: root.cats
                        delegate: SkewChip {
                            required property var modelData
                            readonly property bool on: win.cat === modelData[0] && !win.query
                            label: modelData[1]
                            fill: on ? win.tint : Qt.alpha(Theme.ink, 0.9)
                            size: 17
                            height: 30
                            onClicked: {
                                win.cat = modelData[0];
                                search.text = "";
                                win.sel = 0;
                            }
                        }
                    }
                }

                // Rejilla (fichas flotantes)
                GridView {
                    id: grid
                    y: 160
                    width: 640
                    height: 480
                    clip: true
                    cellWidth: 64
                    cellHeight: 60
                    model: win.items
                    currentIndex: win.sel
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

                    delegate: Item {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool on: index === win.sel
                        width: 64
                        height: 60

                        Rectangle {
                            visible: tile.on
                            x: 7
                            y: 7
                            width: 58
                            height: 52
                            color: Theme.ink
                            transform: Matrix4x4 {
                                matrix: Qt.matrix4x4(1, -0.14, 0, 0.14 * 26, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                            }
                        }
                        Rectangle {
                            x: 3
                            y: 3
                            width: 58
                            height: 52
                            color: tile.on ? win.tint : Qt.alpha(Theme.ink, 0.82)
                            antialiasing: true
                            transform: Matrix4x4 {
                                matrix: Qt.matrix4x4(1, -0.14, 0, 0.14 * 26, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: tile.modelData.e
                            font.pixelSize: 30
                            scale: hover.hovered ? 1.25 : 1
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                        }
                        HoverHandler {
                            id: hover
                            onHoveredChanged: if (hovered)
                                win.sel = tile.index
                        }
                        TapHandler {
                            onTapped: root.insert(tile.modelData)
                        }
                    }
                }

                // Detalle
                Item {
                    x: 670
                    y: 160
                    width: 330
                    height: 300
                    Shape {
                        x: 8
                        y: 8
                        width: 322
                        height: 292
                        ShapePath {
                            fillColor: win.tint
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(19, 0), Qt.point(322, 0), Qt.point(303, 292), Qt.point(0, 292), Qt.point(19, 0)]
                            }
                        }
                    }
                    Shape {
                        width: 322
                        height: 292
                        ShapePath {
                            fillColor: Theme.paper
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(19, 0), Qt.point(322, 0), Qt.point(303, 292), Qt.point(0, 292), Qt.point(19, 0)]
                            }
                        }
                    }
                    Column {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -4
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.current?.e ?? ""
                            font.pixelSize: 110
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 260
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: (win.current?.n ?? "").toUpperCase()
                            color: Theme.ink
                            font.family: "Montserrat"
                            font.pixelSize: 17
                            font.weight: Font.Black
                            font.italic: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.current ? [...win.current.e].map(c => "U+" + c.codePointAt(0).toString(16).toUpperCase()).join(" ") : ""
                            color: Theme.accent
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: Font.ExtraBold
                        }
                    }
                }

                // Recientes
                Column {
                    x: 670
                    y: 490
                    width: 330
                    spacing: 8
                    SkewChip {
                        label: "RECIENTES"
                        fill: Theme.ink
                        fg: win.tint
                        size: 20
                    }
                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: (recent.list ?? []).slice(0, 16)
                            delegate: Item {
                                required property string modelData
                                width: 34
                                height: 34
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.alpha(Theme.ink, 0.82)
                                    transform: Matrix4x4 {
                                        matrix: Qt.matrix4x4(1, -0.14, 0, 0.14 * 17, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    font.pixelSize: 22
                                }
                                TapHandler {
                                    onTapped: {
                                        const it = root.all.find(x => x.e === parent.modelData);
                                        if (it)
                                            root.insert(it);
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: kT.implicitWidth + 24
                    height: 26
                    color: Qt.alpha(Theme.ink, 0.85)
                    Text {
                        id: kT
                        anchors.centerIn: parent
                        textFormat: Text.StyledText
                        text: "<b><font color='" + win.tint + "'>← ↑ → ↓</font></b> ELEGIR · <b><font color='" + win.tint + "'>TAB</font></b> CATEGORÍA · <b><font color='" + win.tint + "'>ENTER</font></b> ESCRIBIR · <b><font color='" + win.tint + "'>ESC</font></b> CERRAR"
                        color: Qt.alpha(Theme.paper, 0.85)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                    }
                }
            }
        }
    }
}

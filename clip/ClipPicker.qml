import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"
import "../services"

// Historial del portapapeles flotante.  qs -c velvet ipc call clipboard toggle
Scope {
    id: root

    property string screenName: ""      // "" = cerrado
    function close() {
        screenName = "";
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            if (root.screenName !== "") {
                root.close();
                return;
            }
            Clipboard.refresh();
            root.screenName = Hyprland.focusedMonitor?.name ?? "";
        }
    }

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
            WlrLayershell.namespace: "velvet-clipboard"
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            readonly property color tint: Theme.accent2
            readonly property var kindColor: ({
                    "TEXTO": Theme.paper,
                    "IMAGEN": Theme.accent,
                    "ENLACE": Theme.accent2,
                    "CÓDIGO": Theme.accent3
                })

            property string query: ""
            readonly property var items: {
                const q = query.toLowerCase();
                return q ? Clipboard.entries.filter(e => e.preview.toLowerCase().includes(q)) : Clipboard.entries;
            }
            property int sel: 0
            readonly property var current: items.length ? items[Math.min(sel, items.length - 1)] : null
            onCurrentChanged: Clipboard.load(current)

            onVisibleChanged: if (visible) {
                search.text = "";
                sel = 0;
                search.input.forceActiveFocus();
            }

            function paste() {
                if (current) {
                    const c = current;
                    root.close();
                    Clipboard.paste(c);
                }
            }
            function copy() {
                if (current) {
                    Clipboard.copy(current);
                    root.close();
                }
            }

            // Clic fuera: cerrar
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Item {
                id: stage
                width: 1140
                height: 700
                anchors.centerIn: parent
                MouseArea {
                    anchors.fill: parent
                }   // no cerrar al hacer clic dentro

                // Cabecera
                Row {
                    spacing: 18
                    BigTitle {
                        text: "PORTAPAPELES"
                        shadow: win.tint
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        width: countT.implicitWidth + 20
                        height: 22
                        color: Qt.alpha(Theme.ink, 0.85)
                        Text {
                            id: countT
                            anchors.centerIn: parent
                            text: Clipboard.entries.length + " ENTRADAS · CLIPHIST"
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
                    width: 380
                    accent: win.tint
                    placeholder: "buscar en el historial…"
                    onTextChanged: {
                        win.query = text;
                        win.sel = 0;
                    }
                    onKeyPressed: event => {
                        const shift = event.modifiers & Qt.ShiftModifier, ctrl = event.modifiers & Qt.ControlModifier;
                        switch (event.key) {
                        case Qt.Key_Escape:
                            root.close();
                            break;
                        case Qt.Key_Down:
                            win.sel = Math.min(win.items.length - 1, win.sel + 1);
                            break;
                        case Qt.Key_Up:
                            win.sel = Math.max(0, win.sel - 1);
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            shift ? win.copy() : win.paste();
                            break;
                        case Qt.Key_Delete:
                            ctrl ? Clipboard.wipe() : (win.current && Clipboard.remove(win.current));
                            break;
                        default:
                            return;
                        }
                        event.accepted = true;
                    }
                }

                // Pila de cartas
                ListView {
                    id: listView
                    x: 0
                    y: 110
                    width: 560
                    height: 560
                    clip: true
                    spacing: 8
                    model: win.items
                    currentIndex: win.sel
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Item {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property bool on: index === win.sel
                        width: 520
                        height: 66

                        Item {
                            anchors.fill: parent
                            transform: [
                                Rotation {
                                    origin.x: 260
                                    origin.y: 33
                                    angle: card.on ? -1.5 : 0
                                    Behavior on angle {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                },
                                Translate {
                                    x: card.on ? 30 : 0
                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 220
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                            ]

                            Shape {
                                x: 8
                                y: 8
                                width: 520
                                height: 66
                                visible: card.on
                                ShapePath {
                                    fillColor: win.tint
                                    strokeColor: "transparent"
                                    PathPolyline {
                                        path: [Qt.point(16, 0), Qt.point(520, 0), Qt.point(504, 66), Qt.point(0, 66), Qt.point(16, 0)]
                                    }
                                }
                            }
                            Shape {
                                width: 520
                                height: 66
                                ShapePath {
                                    fillColor: card.on ? Theme.paper : Qt.alpha(Theme.surface, 0.95)
                                    strokeColor: "transparent"
                                    PathPolyline {
                                        path: [Qt.point(16, 0), Qt.point(520, 0), Qt.point(504, 66), Qt.point(0, 66), Qt.point(16, 0)]
                                    }
                                }
                            }
                            Row {
                                x: 26
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12
                                SkewChip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: card.modelData.kind
                                    fill: win.kindColor[card.modelData.kind]
                                    size: 15
                                    padding: 8
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 520 - 26 - 100 - 50
                                    text: card.modelData.preview
                                    elide: Text.ElideRight
                                    color: card.on ? Theme.ink : Theme.paper
                                    font.family: card.modelData.kind === "CÓDIGO" || card.modelData.kind === "ENLACE" ? "JetBrains Mono" : "Montserrat"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: "#" + String(card.index + 1).padStart(2, "0")
                                color: card.on ? win.tint : Qt.alpha(Theme.telemetry, 0.6)
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: win.sel = card.index
                            onDoubleClicked: win.paste()
                        }
                    }
                }

                // Vista previa
                Item {
                    x: 560
                    y: 110
                    width: 580
                    height: 470

                    Shape {
                        x: 10
                        y: 10
                        width: 570
                        height: 460
                        ShapePath {
                            fillColor: win.tint
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(17, 0), Qt.point(570, 0), Qt.point(553, 460), Qt.point(0, 460), Qt.point(17, 0)]
                            }
                        }
                    }
                    Shape {
                        width: 570
                        height: 460
                        ShapePath {
                            fillColor: Theme.paper
                            strokeColor: "transparent"
                            PathPolyline {
                                path: [Qt.point(17, 0), Qt.point(570, 0), Qt.point(553, 460), Qt.point(0, 460), Qt.point(17, 0)]
                            }
                        }
                    }
                    Row {
                        x: 40
                        y: 26
                        spacing: 10
                        SkewChip {
                            label: "VISTA PREVIA"
                            fill: Theme.ink
                            size: 20
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: win.current ? win.current.kind + (win.current.kind === "IMAGEN" ? " · " + win.current.info : " · " + Clipboard.fullText.length + " CARACTERES") : "VACÍO"
                            color: win.tint
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: Font.ExtraBold
                            font.letterSpacing: 1
                        }
                    }
                    Image {
                        visible: win.current?.kind === "IMAGEN"
                        x: 40
                        y: 72
                        width: 480
                        height: 360
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        source: visible ? Clipboard.imagePath : ""
                    }
                    Text {
                        visible: win.current !== null && win.current.kind !== "IMAGEN"
                        x: 40
                        y: 72
                        width: 480
                        height: 360
                        clip: true
                        text: Clipboard.fullText
                        wrapMode: Text.WrapAnywhere
                        elide: Text.ElideRight
                        color: Theme.ink
                        font.family: win.current?.kind === "CÓDIGO" || win.current?.kind === "ENLACE" ? "JetBrains Mono" : "Montserrat"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        lineHeight: 1.4
                    }
                    Text {
                        visible: win.items.length === 0
                        anchors.centerIn: parent
                        text: Clipboard.entries.length ? "SIN RESULTADOS" : "HISTORIAL VACÍO"
                        color: Qt.alpha(Theme.ink, 0.4)
                        font.family: "Bebas Neue"
                        font.pixelSize: 40
                        font.letterSpacing: 4
                    }
                }

                // Acciones
                Row {
                    x: 570
                    y: 610
                    spacing: 10
                    SkewChip {
                        label: "ENTER · PEGAR"
                        fill: win.tint
                        shadow: Theme.ink
                        size: 22
                        padding: 18
                        height: 40
                        onClicked: win.paste()
                    }
                    SkewChip {
                        label: "SHIFT+ENTER · COPIAR"
                        fill: Qt.alpha(Theme.ink, 0.85)
                        border: Qt.alpha(Theme.paper, 0.4)
                        size: 20
                        height: 40
                        onClicked: win.copy()
                    }
                    SkewChip {
                        label: "SUPR · BORRAR"
                        fill: Qt.alpha(Theme.ink, 0.85)
                        border: Qt.alpha(Theme.paper, 0.4)
                        size: 20
                        height: 40
                        onClicked: if (win.current)
                            Clipboard.remove(win.current)
                    }
                    SkewChip {
                        label: "CTRL+SUPR · VACIAR"
                        fill: Theme.accent
                        size: 20
                        height: 40
                        onClicked: Clipboard.wipe()
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: hintT.implicitWidth + 24
                    height: 26
                    color: Qt.alpha(Theme.ink, 0.85)
                    Text {
                        id: hintT
                        anchors.centerIn: parent
                        textFormat: Text.StyledText
                        text: "<b><font color='" + win.tint + "'>↑ ↓</font></b> ELEGIR · <b><font color='" + win.tint + "'>ENTER</font></b> PEGAR · <b><font color='" + win.tint + "'>ESC</font></b> CERRAR"
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

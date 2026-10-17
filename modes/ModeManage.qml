import QtQuick
import "../config"
import "../clip"

// Administrar modos: lista con editar / ocultar-mostrar / borrar + nuevo modo.
// Va dentro de ModeSelect (página "manage"), en coordenadas del escenario 1600×900.
Item {
    id: root
    anchors.fill: parent

    property int sel: 0
    readonly property var rows: Modes.all
    readonly property bool full: Modes.shown.length >= Modes.maxShown
    // Estilo de la fila elegida: ModeSelect tiñe el fondo con él
    readonly property string focusStyle: rows[Math.min(sel, rows.length - 1)]?.style ?? "general"
    // Modo propio pendiente de confirmar el borrado (se pulsa dos veces)
    property string confirmDel: ""

    signal edit(string id)      // "" = nuevo
    signal back
    signal say(string text)

    function move(d) {
        sel = (sel + d + rows.length) % rows.length;
        confirmDel = "";
    }
    function isHidden(id) {
        return (Config.hiddenModes ?? []).includes(id);
    }
    // Tecla del selector (1–6) o "—" si está oculto
    function keyOf(id) {
        const i = Modes.shown.findIndex(m => m.id === id);
        return i < 0 ? "—" : String(i + 1);
    }
    function summary(id) {
        const s = Config.forMode(id);
        const prof = ({
                "power-saver": "AHORRO",
                "balanced": "EQUILIBRADO",
                "performance": "RENDIMIENTO"
            })[s.profile] ?? "EQUILIBRADO";
        return prof + " · BLOQUEO " + (s.lock ? s.lock + " MIN" : "NUNCA") + (s.dnd ? " · NO MOLESTAR" : "") + (s.gamemode ? " · GAMEMODE" : "");
    }

    function toggle(m) {
        let err = "";
        if (m.builtin) {
            err = isHidden(m.id) ? Modes.unhide(m.id) : Modes.hide(m.id);
            if (!err)
                say(m.name + (isHidden(m.id) ? " OCULTO" : " VUELVE AL SELECTOR"));
        } else if (confirmDel !== m.id) {
            confirmDel = m.id;
            delT.restart();
            say("PULSA OTRA VEZ PARA BORRAR " + m.name);
            return;
        } else {
            err = Modes.remove(m.id);
            if (!err)
                say(m.name + " BORRADO");
            confirmDel = "";
        }
        if (err)
            say(err);
        sel = Math.min(sel, rows.length - 1);
    }
    function newMode() {
        if (full)
            say("MÁXIMO " + Modes.maxShown + " MODOS EN EL SELECTOR · OCULTA ALGUNO");
        else
            edit("");
    }
    Timer {
        id: delT
        interval: 3000
        onTriggered: root.confirmDel = ""
    }

    // Tríada inclinada pequeña
    component Trio: Row {
        property var colors: []
        spacing: 4
        Repeater {
            model: parent.colors
            Rectangle {
                required property var modelData
                width: 18
                height: 30
                color: modelData
                border.width: 2
                border.color: Theme.ink
                antialiasing: true
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -0.21, 0, 0.21 * 15, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
            }
        }
    }

    // ── Lista ──
    Column {
        x: 56
        y: 200
        width: 980

        // Cabecera de columnas
        Item {
            width: parent.width
            height: 30
            Repeater {
                model: [
                    {
                        x: 14,
                        t: "TECLA"
                    },
                    {
                        x: 90,
                        t: "ESTILO"
                    },
                    {
                        x: 226,
                        t: "MODO"
                    },
                    {
                        x: 620,
                        t: "ORIGEN"
                    }
                ]
                Text {
                    required property var modelData
                    x: modelData.x
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.t
                    color: Theme.palettes[root.focusStyle].telemetry
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 9
                        weight: Font.ExtraBold
                        letterSpacing: 2
                    }
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: Qt.alpha(Theme.paper, 0.25)
            }
        }

        Repeater {
            model: root.rows
            Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: root.sel === index
                readonly property bool hid: root.isHidden(modelData.id)
                readonly property var trio: Theme.palettes[modelData.style].trio
                width: parent.width
                height: 84

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: if (root.sel !== row.index) {
                        root.sel = row.index;
                        root.confirmDel = "";
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    visible: row.on
                    color: Qt.alpha(Theme.paper, 0.05)
                    Rectangle {
                        width: 6
                        height: parent.height
                        color: row.trio[0]
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.alpha(Theme.paper, 0.12)
                }

                Item {
                    anchors.fill: parent
                    opacity: row.hid ? 0.45 : 1

                    // Tecla
                    Rectangle {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 40
                        rotation: -6
                        color: row.hid ? "transparent" : Theme.ink
                        border.width: 3
                        border.color: Theme.paper
                        Text {
                            anchors.centerIn: parent
                            text: root.keyOf(row.modelData.id)
                            color: Theme.paper
                            font {
                                family: "Bebas Neue"
                                pixelSize: 26
                            }
                        }
                    }
                    Trio {
                        x: 90
                        anchors.verticalCenter: parent.verticalCenter
                        colors: row.trio
                    }
                    Column {
                        x: 226
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: row.modelData.name
                            color: Theme.paper
                            font {
                                family: "Bebas Neue"
                                pixelSize: 40
                                letterSpacing: 2
                            }
                        }
                        Text {
                            width: 380
                            elide: Text.ElideRight
                            text: Modes.styleLabel(row.modelData.style) + " · " + root.summary(row.modelData.id)
                            color: "#C3C5D9"
                            font {
                                family: "JetBrains Mono"
                                pixelSize: 9
                                bold: true
                                letterSpacing: 1.5
                            }
                        }
                    }
                    // Origen
                    Rectangle {
                        x: 620
                        anchors.verticalCenter: parent.verticalCenter
                        width: orT.implicitWidth + 20
                        height: orT.implicitHeight + 8
                        color: "transparent"
                        border.width: 2
                        border.color: row.modelData.builtin ? Qt.alpha(Theme.paper, 0.4) : row.trio[0]
                        Text {
                            id: orT
                            anchors.centerIn: parent
                            text: row.modelData.builtin ? "DE SERIE" : "PROPIO"
                            color: row.modelData.builtin ? "#C3C5D9" : row.trio[0]
                            font {
                                family: "JetBrains Mono"
                                pixelSize: 10
                                weight: Font.ExtraBold
                                letterSpacing: 2
                            }
                        }
                    }
                }

                // Botones (sin atenuar aunque el modo esté oculto)
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    SkewChip {
                        height: 38
                        label: "EDITAR"
                        fill: "transparent"
                        fg: Theme.paper
                        border: Qt.alpha(Theme.paper, 0.4)
                        size: 21
                        padding: 16
                        onClicked: root.edit(row.modelData.id)
                    }
                    SkewChip {
                        readonly property bool armed: root.confirmDel === row.modelData.id
                        height: 38
                        label: row.modelData.builtin ? (row.hid ? "MOSTRAR" : "OCULTAR") : (armed ? "¿SEGURO? ✕" : "BORRAR")
                        fill: row.modelData.builtin ? (row.hid ? Theme.paper : "transparent") : (armed ? "#E60012" : "transparent")
                        fg: row.modelData.builtin ? (row.hid ? Theme.ink : Theme.paper) : (armed ? Theme.paper : "#FF5A66")
                        border: row.modelData.builtin ? (row.hid ? Theme.paper : Qt.alpha(Theme.paper, 0.4)) : "#E60012"
                        size: 21
                        padding: 16
                        onClicked: root.toggle(row.modelData)
                    }
                }
            }
        }

        Item {
            width: 1
            height: 20
        }
        SkewChip {
            height: 52
            label: root.full ? "SELECTOR LLENO (" + Modes.maxShown + ") · OCULTA ALGUNO" : "+ NUEVO MODO"
            fill: "transparent"
            fg: root.full ? Qt.alpha(Theme.paper, 0.4) : Theme.paper
            border: root.full ? Qt.alpha(Theme.paper, 0.3) : Theme.paper
            size: 28
            padding: 24
            onClicked: root.newMode()
        }
    }

    // ── Reglas ──
    Item {
        x: 1090
        y: 200
        width: 440
        height: rules.implicitHeight + 40
        rotation: 1.5
        Rectangle {
            x: 9
            y: 9
            width: parent.width
            height: parent.height
            color: Theme.palettes[root.focusStyle].trio[1]
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.ink
            border.width: 3
            border.color: Theme.paper
        }
        Column {
            id: rules
            x: 22
            y: 20
            width: parent.width - 44
            spacing: 8
            Text {
                text: "REGLAS DE LA CASA"
                color: Theme.paper
                bottomPadding: 4
                font {
                    family: "Bebas Neue"
                    pixelSize: 30
                    letterSpacing: 2
                }
            }
            Repeater {
                model: ["LOS MODOS DE SERIE SE OCULTAN, NO SE BORRAN: PUEDES RECUPERARLOS", "LOS PROPIOS SE BORRAN DEL TODO (PULSA DOS VECES)", "MÁXIMO " + Modes.maxShown + " MODOS EN EL SELECTOR · SIEMPRE AL MENOS 1", "EL ESTILO DECIDE COLORES, FONDOS Y TERMINAL"]
                Row {
                    required property string modelData
                    spacing: 10
                    Text {
                        text: "▶"
                        color: Theme.palettes[root.focusStyle].trio[0]
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 11
                            weight: Font.ExtraBold
                        }
                    }
                    Text {
                        width: 370
                        wrapMode: Text.WordWrap
                        text: parent.modelData
                        color: Theme.paper
                        lineHeight: 1.3
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 11
                            bold: true
                            letterSpacing: 1
                        }
                    }
                }
            }
        }
    }
    SkewChip {
        x: 1090
        y: 200 + rules.implicitHeight + 80
        height: 44
        label: "← VOLVER AL SELECTOR"
        fill: "transparent"
        fg: Theme.paper
        border: Theme.paper
        size: 23
        padding: 20
        onClicked: root.back()
    }
}

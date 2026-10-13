import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.UPower
import "../services"

Item {
    id: root

    required property var ctx

    // Paleta
    readonly property color red: "#E60012"
    readonly property color blue: "#0055FF"
    readonly property color yellow: "#FFE600"
    readonly property color ink: "#0D0E12"
    readonly property color paper: "#F5F5F7"

    // Escala del diseño (1600×900)
    readonly property real s: Math.min(width / 1600, height / 900)

    // ── Datos ───────────────────────────────────────────
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property var days: ["DOMINGO", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO"]
    readonly property string hm: Qt.formatTime(clock.date, "hh:mm")
    readonly property string weekday: days[clock.date.getDay()]
    readonly property string dateStr: Qt.formatDate(clock.date, "dd.MM.yyyy")

    readonly property string franja: {
        const h = clock.hours;
        return h < 6 ? "ESTA MADRUGADA" : h < 12 ? "ESTA MAÑANA" : h < 20 ? "ESTA TARDE" : "ESTA NOCHE";
    }
    // Usa la misma fórmula de batería / avisos que en Corner.qml si difiere
    readonly property int bat: Math.round(UPower.displayDevice.percentage * 100)
    readonly property int unread: Notifs.unread

    readonly property string ticker: {
        let t = "";
        if (Weather.ready)
            t += Weather.condition.toUpperCase() + " " + franja + " · " + Weather.temp + "° · ";
        if (UPower.displayDevice.isLaptopBattery)
            t += "BAT " + bat + "% · ";
        t += unread + (unread === 1 ? " AVISO SIN LEER" : " AVISOS SIN LEER");
        return t;
    }

    // ── Fondo P5: rojo + trama + esquirlas ──────────────
    Rectangle {
        anchors.fill: parent
        color: root.red
    }

    Canvas {
        anchors.fill: parent
        onPaint: {
            const g = getContext("2d");
            const step = 14 * root.s, r = 1.7 * root.s;
            g.fillStyle = "rgba(13,14,18,0.35)";
            for (let y = 0; y < height; y += step)
                for (let x = 0; x < width; x += step) {
                    g.beginPath();
                    g.arc(x, y, r, 0, Math.PI * 2);
                    g.fill();
                }
        }
    }

    Shape {
        anchors.fill: parent
        ShapePath {
            fillColor: root.ink
            strokeWidth: -1
            PathPolyline {
                path: [Qt.point(0, 0), Qt.point(root.width * 0.22, 0), Qt.point(root.width * 0.10, root.height), Qt.point(0, root.height)]
            }
        }
        ShapePath {
            fillColor: root.ink
            strokeWidth: -1
            PathPolyline {
                path: [Qt.point(root.width * 0.86, 0), Qt.point(root.width, 0), Qt.point(root.width, root.height), Qt.point(root.width * 0.74, root.height)]
            }
        }
    }

    // Tajo: banda de precaución P4 + línea azul
    Item {
        id: slash
        width: root.width * 1.6
        height: 60 * root.s
        x: root.width * 0.5625 - width / 2
        y: root.height * (600 / 900)
        rotation: -14

        Canvas {
            id: hazard
            width: parent.width
            height: 40 * root.s
            onPaint: {
                const g = getContext("2d"), w = 20 * root.s;
                g.fillStyle = "#FFE600";
                g.fillRect(0, 0, width, height);
                g.fillStyle = "#0D0E12";
                for (let x = -height; x < width; x += w * 2) {
                    g.beginPath();
                    g.moveTo(x, height);
                    g.lineTo(x + w, height);
                    g.lineTo(x + w + height, 0);
                    g.lineTo(x + height, 0);
                    g.closePath();
                    g.fill();
                }
            }
        }
        Rectangle {
            y: 52 * root.s
            width: parent.width
            height: 8 * root.s
            color: root.blue
        }

        transform: Translate {
            id: slashT
            x: -root.width * 2
        }
        NumberAnimation {
            running: true
            target: slashT
            property: "x"
            to: 0
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    // ── Escenario a escala ──────────────────────────────
    Item {
        id: stage
        width: 1600
        height: 900
        anchors.centerIn: parent
        scale: root.s

        // Fecha recortada
        Column {
            x: 56
            y: 56
            spacing: 14
            Item {
                width: wd.implicitWidth + 36
                height: wd.implicitHeight
                rotation: -3
                SkewRect {
                    x: 6
                    y: 6
                    width: parent.width
                    height: parent.height
                    color: root.ink
                }
                SkewRect {
                    anchors.fill: parent
                    color: root.yellow
                }
                Text {
                    id: wd
                    anchors.centerIn: parent
                    text: root.weekday
                    color: root.ink
                    font.family: "Bebas Neue"
                    font.pixelSize: 52
                    font.letterSpacing: 4
                }
            }
            Item {
                width: dt.implicitWidth + 28
                height: dt.implicitHeight
                rotation: 2
                SkewRect {
                    anchors.fill: parent
                    color: root.paper
                }
                Text {
                    id: dt
                    anchors.centerIn: parent
                    text: root.dateStr
                    color: root.ink
                    font.family: "Bebas Neue"
                    font.pixelSize: 36
                    font.letterSpacing: 3
                }
            }
        }

        // Televisor
        Item {
            id: tv
            x: 300
            y: 70
            width: 1000
            height: 500
            rotation: -3
            transform: Scale {
                id: tvScale
                origin.x: tv.width / 2
                origin.y: tv.height / 2
                yScale: 0.01
                xScale: 1.2
            }
            ParallelAnimation {
                running: true
                NumberAnimation {
                    target: tvScale
                    property: "yScale"
                    to: 1
                    duration: 500
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: tvScale
                    property: "xScale"
                    to: 1
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                x: 16
                y: 16
                width: parent.width
                height: parent.height
                color: root.ink
            }
            Rectangle {
                anchors.fill: parent
                color: root.paper
                border.color: root.ink
                border.width: 4

                Item {
                    id: tvScreen
                    anchors.fill: parent
                    anchors.margins: 18
                    clip: true

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PauseAnimation {
                            duration: 1440
                        }
                        NumberAnimation {
                            to: 0.8
                            duration: 60
                        }
                        NumberAnimation {
                            to: 1
                            duration: 60
                        }
                        PauseAnimation {
                            duration: 1440
                        }
                    }

                    Shape {
                        anchors.fill: parent
                        ShapePath {
                            strokeWidth: -1
                            fillGradient: RadialGradient {
                                centerX: tvScreen.width / 2
                                centerY: tvScreen.height / 2
                                focalX: centerX
                                focalY: centerY
                                centerRadius: tvScreen.width * 0.6
                                GradientStop {
                                    position: 0
                                    color: "#2A2A22"
                                }
                                GradientStop {
                                    position: 1
                                    color: "#0B0B09"
                                }
                            }
                            PathPolyline {
                                path: [Qt.point(0, 0), Qt.point(tvScreen.width, 0), Qt.point(tvScreen.width, tvScreen.height), Qt.point(0, tvScreen.height)]
                            }
                        }
                    }

                    // Scanlines
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const g = getContext("2d");
                            g.fillStyle = "rgba(255,255,255,0.05)";
                            for (let y = 0; y < height; y += 4)
                                g.fillRect(0, y, width, 1);
                        }
                    }

                    // Esquina roja de carta
                    Shape {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 90
                        height: 90
                        ShapePath {
                            fillColor: root.red
                            strokeWidth: -1
                            PathPolyline {
                                path: [Qt.point(0, 0), Qt.point(90, 0), Qt.point(90, 90)]
                            }
                        }
                    }

                    // OSD
                    Text {
                        x: 24
                        y: 18
                        text: "CH 04"
                        color: root.yellow
                        style: Text.Raised
                        styleColor: root.ink
                        font.family: "JetBrains Mono"
                        font.pixelSize: 24
                        font.weight: Font.ExtraBold
                    }
                    Text {
                        x: 24
                        y: 54
                        text: "AVISO PARA ALDURAN"
                        color: Qt.rgba(1, 0.9, 0, 0.7)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 3
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 104
                        y: 22
                        spacing: 6
                        Text {
                            text: "●"
                            color: root.yellow
                            font.pixelSize: 12
                            Timer {
                                interval: 500
                                running: true
                                repeat: true
                                onTriggered: parent.visible = !parent.visible
                            }
                        }
                        Text {
                            text: "EN DIRECTO"
                            color: root.yellow
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                        }
                    }

                    // Reloj nota de rescate con aberración cromática
                    Row {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -18
                        spacing: 6

                        Repeater {
                            model: root.hm.split("")
                            delegate: Rectangle {
                                id: letter
                                required property string modelData
                                required property int index

                                readonly property var looks: [["#FFE600", "#0D0E12", 0], ["#F5F5F7", "#0D0E12", 3], ["transparent", "#FFE600", 0], ["#E60012", "#F5F5F7", 0], ["#0055FF", "#F5F5F7", 0]]
                                readonly property var fonts: ["Bebas Neue", "JetBrains Mono", "Montserrat"]
                                readonly property var weights: [Font.Normal, Font.ExtraBold, Font.Black]
                                readonly property var rots: [-7, 5, -3, 8, -5]
                                readonly property var sizes: [150, 120, 90, 140, 126]
                                readonly property var look: looks[index % 5]

                                anchors.verticalCenter: parent.verticalCenter
                                width: glyph.implicitWidth + 28
                                height: glyph.implicitHeight * 0.92
                                color: look[0]
                                border.width: look[2]
                                border.color: "#0D0E12"
                                rotation: rots[index % 5]
                                antialiasing: true
                                transform: Translate {
                                    y: letter.index % 2 ? -8 : 8
                                }

                                // Fantasmas rojo / azul + glifo principal
                                Repeater {
                                    model: [[-4, Qt.rgba(0.9, 0, 0.07, 0.7)], [4, Qt.rgba(0, 0.33, 1, 0.7)]]
                                    delegate: Text {
                                        required property var modelData
                                        anchors.centerIn: parent
                                        anchors.horizontalCenterOffset: modelData[0]
                                        color: modelData[1]
                                        text: glyph.text
                                        font: glyph.font
                                    }
                                }
                                Text {
                                    id: glyph
                                    anchors.centerIn: parent
                                    text: letter.modelData
                                    color: letter.look[1]
                                    font.family: letter.fonts[letter.index % 3]
                                    font.weight: letter.weights[letter.index % 3]
                                    font.pixelSize: letter.modelData === ":" ? 100 : letter.sizes[letter.index % 5]
                                }
                            }
                        }
                    }

                    // Pronóstico real
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 42
                        color: root.yellow
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 24
                            spacing: 18
                            Item {
                                width: fc.implicitWidth + 20
                                height: fc.implicitHeight
                                anchors.verticalCenter: parent.verticalCenter
                                SkewRect {
                                    anchors.fill: parent
                                    color: root.ink
                                }
                                Text {
                                    id: fc
                                    anchors.centerIn: parent
                                    text: "PRONÓSTICO"
                                    color: root.yellow
                                    font.family: "Bebas Neue"
                                    font.pixelSize: 22
                                    font.letterSpacing: 3
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.ticker
                                color: root.ink
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                font.weight: Font.ExtraBold
                                font.letterSpacing: 1
                            }
                        }
                    }
                }
            }
        }

        // Caja de diálogo P4 con corte P5
        Item {
            id: dialog
            x: 330
            y: 700
            width: 940
            height: 118
            visible: !root.ctx.success
            transform: Translate {
                id: shakeT
            }

            SequentialAnimation {
                id: shake
                NumberAnimation {
                    target: shakeT
                    property: "x"
                    to: -14
                    duration: 90
                }
                NumberAnimation {
                    target: shakeT
                    property: "x"
                    to: 12
                    duration: 90
                }
                NumberAnimation {
                    target: shakeT
                    property: "x"
                    to: -8
                    duration: 90
                }
                NumberAnimation {
                    target: shakeT
                    property: "x"
                    to: 5
                    duration: 90
                }
                NumberAnimation {
                    target: shakeT
                    property: "x"
                    to: 0
                    duration: 90
                }
            }
            Connections {
                target: root.ctx
                function onFailure() {
                    shake.restart();
                }
                function onPwChanged() {
                    if (input.text !== root.ctx.pw)
                        input.text = root.ctx.pw;
                }
            }

            SkewRect {
                skew: -10
                x: 10
                y: 32
                width: parent.width
                height: 96
                color: root.ink
            }
            SkewRect {
                id: box
                skew: -10
                y: 22
                width: parent.width
                height: 96
                color: root.ink
                border.width: 3
                border.color: root.ctx.failed ? root.red : root.yellow
            }

            // Pestaña de nombre
            Item {
                x: 28
                y: 0
                width: nm.implicitWidth + 44
                height: 42
                SkewRect {
                    skew: -10
                    x: 4
                    y: 4
                    width: parent.width
                    height: parent.height
                    color: root.ink
                }
                SkewRect {
                    skew: -10
                    anchors.fill: parent
                    color: root.yellow
                }
                Text {
                    id: nm
                    anchors.centerIn: parent
                    text: "ALDURAN"
                    color: root.ink
                    font.family: "Bebas Neue"
                    font.pixelSize: 28
                    font.letterSpacing: 3
                }
            }

            RowLayout {
                x: 40
                y: 22 + 16
                width: parent.width - 80
                height: 64
                spacing: 14

                Text {
                    text: "▶"
                    color: root.yellow
                    font.family: "Bebas Neue"
                    font.pixelSize: 28
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: input
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        focus: true
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: root.paper
                        font.family: "Bebas Neue"
                        font.pixelSize: 36
                        font.letterSpacing: 10
                        onTextEdited: root.ctx.pw = text
                        onAccepted: root.ctx.tryUnlock()
                        Keys.onEscapePressed: if (root.ctx.testMode)
                            root.ctx.release()
                        Component.onCompleted: forceActiveFocus()
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: root.ctx.failed ? "…upss, te equivocaste!" : "contraseña…"
                        color: root.ctx.failed ? "#FF4D5E" : Qt.rgba(0.96, 0.96, 0.97, 0.35)
                        font.family: "Bebas Neue"
                        font.pixelSize: 36
                        font.letterSpacing: 4
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        width: parent.width
                        height: 2
                        color: Qt.rgba(1, 0.9, 0, 0.5)
                    }
                }

                Item {
                    Layout.preferredWidth: bt.implicitWidth + 40
                    Layout.preferredHeight: 44
                    SkewRect {
                        skew: -10
                        x: 4
                        y: 4
                        width: parent.width
                        height: parent.height
                        color: root.yellow
                    }
                    SkewRect {
                        skew: -10
                        anchors.fill: parent
                        color: root.red
                    }
                    Text {
                        id: bt
                        anchors.centerIn: parent
                        text: root.ctx.busy ? "SINTONIZANDO…" : "SINTONIZAR ▶▶"
                        color: root.paper
                        font.family: "Bebas Neue"
                        font.pixelSize: 24
                        font.letterSpacing: 3
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.ctx.tryUnlock()
                    }
                }
            }
        }
    }

    // Clic en cualquier sitio devuelve el foco al campo
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: input.forceActiveFocus()
    }

    // ── Desbloqueado ────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.ink
        visible: root.ctx.success
        onVisibleChanged: if (visible)
            stampIn.restart()

        Canvas {
            anchors.fill: parent
            onPaint: {
                const g = getContext("2d");
                g.fillStyle = "rgba(255,255,255,0.04)";
                for (let y = 0; y < height; y += 4)
                    g.fillRect(0, y, width, 1);
            }
        }

        Item {
            id: stamp
            anchors.centerIn: parent
            width: st.implicitWidth + 80 * root.s
            height: st.implicitHeight
            rotation: -6
            Rectangle {
                x: 12 * root.s
                y: 12 * root.s
                width: parent.width
                height: parent.height
                color: root.red
            }
            Rectangle {
                anchors.fill: parent
                color: root.yellow
            }
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -4 * root.s
                text: st.text
                font: st.font
                color: Qt.rgba(0.9, 0, 0.07, 0.6)
            }
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 4 * root.s
                text: st.text
                font: st.font
                color: Qt.rgba(0, 0.33, 1, 0.6)
            }
            Text {
                id: st
                anchors.centerIn: parent
                text: "¡BIENVENIDO ALE!"
                color: root.ink
                font.family: "Bebas Neue"
                font.pixelSize: 150 * root.s
                font.letterSpacing: 10 * root.s
            }

            ParallelAnimation {
                id: stampIn
                NumberAnimation {
                    target: stamp
                    property: "scale"
                    from: 2.2
                    to: 1
                    duration: 400
                    easing.type: Easing.OutBack
                }
                NumberAnimation {
                    target: stamp
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                }
            }
        }
    }
}

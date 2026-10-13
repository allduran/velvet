import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Shapes
import "../config"
import "../components"
import "../services"

Item {
    id: root
    property var n
    property int order: 0

    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    readonly property color tone: critical ? Theme.accent : Theme.at(n?.id ?? 0)
    readonly property var actions: (n?.actions ?? []).filter(a => a.identifier !== "default")
    readonly property real timeout: critical ? 0 : (n?.expireTimeout > 0 ? n.expireTimeout * 1000 : 7000)
    readonly property string iconSrc: n?.image ? n.image : n?.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""
    property real fill: 1
    property var born: new Date()
    property int tick: 0

    width: 450
    height: Math.max(82, content.implicitHeight)

    // Inclinación de toda la burbuja + entrada desde la derecha
    transform: [
        Matrix4x4 {
            matrix: Qt.matrix4x4(1, -0.14, 0, 0.14 * root.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        },
        Translate {
            id: slide
        }
    ]
    Component.onCompleted: {
        slide.x = 520;
        enter.start();
    }
    NumberAnimation {
        id: enter
        target: slide
        property: "x"
        to: 0
        duration: 320
        easing.type: Easing.OutBack
    }

    // Tiempo restante (se pausa con el ratón encima)
    NumberAnimation on fill {
        id: life
        running: root.timeout > 0
        paused: running && (hover.hovered || Ui.cornerScreen !== "")
        from: 1
        to: 0
        duration: root.timeout
        onFinished: Notifs.drop(root.n)
    }
    HoverHandler {
        id: hover
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.tick++
    }
    function ago() {
        tick;
        const m = Math.round((Date.now() - born.getTime()) / 60000);
        return m < 1 ? "AHORA" : "HACE " + m + " MIN";
    }

    // ── Avatar ──
    Item {
        id: avatar
        y: 26
        width: 56
        height: 56
        Rectangle {
            x: 4
            y: 4
            width: parent.width
            height: parent.height
            color: Theme.ink
        }
        Rectangle {
            anchors.fill: parent
            color: root.critical ? Theme.accent : Theme.paper
            Rectangle {
                width: 5
                height: parent.height
                color: root.critical ? Theme.accent3 : root.tone
            }
            IconImage {
                visible: root.iconSrc !== ""
                anchors.centerIn: parent
                implicitSize: 36
                source: root.iconSrc
            }
            Text {
                visible: root.iconSrc === ""
                anchors.centerIn: parent
                text: root.critical ? "!" : (root.n?.appName ?? "?").slice(0, 2).toUpperCase()
                color: root.critical ? Theme.paper : Theme.ink
                font {
                    family: "Bebas Neue"
                    pixelSize: 26
                    letterSpacing: 1
                }
            }
        }
    }

    // ── Contenido ──
    Column {
        id: content
        x: 66
        width: parent.width - 66
        spacing: 6

        // Cabecera: app · hora · cerrar
        Item {
            width: parent.width
            height: 22
            Row {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Rectangle {
                    width: appT.implicitWidth + 16
                    height: 18
                    color: root.tone
                    Text {
                        id: appT
                        anchors.centerIn: parent
                        text: (root.n?.appName || "SISTEMA").toUpperCase()
                        color: Theme.on(root.tone)
                        font {
                            family: "JetBrains Mono"
                            pixelSize: 10
                            weight: Font.ExtraBold
                            letterSpacing: 1.5
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.ago()
                    color: Theme.telemetry
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 9
                        bold: true
                        letterSpacing: 1
                    }
                }
            }
            Rectangle {
                anchors.right: parent.right
                width: 22
                height: 22
                color: closeArea.containsMouse ? Theme.paper : Qt.alpha(Theme.ink, 0.9)
                border {
                    width: 1
                    color: Qt.alpha(Theme.paper, 0.4)
                }
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: closeArea.containsMouse ? Theme.ink : Theme.paper
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 13
                        weight: Font.ExtraBold
                    }
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.n.dismiss()
                }
            }
        }

        // Burbuja con cola dentada
        Item {
            id: bubble
            width: parent.width
            height: bodyCol.implicitHeight + 24

            Shape {
                x: 6
                y: 6
                width: parent.width
                height: parent.height
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.tone
                    strokeColor: "transparent"
                    startX: 16
                    startY: 0
                    PathLine {
                        x: bubble.width
                        y: 0
                    }
                    PathLine {
                        x: bubble.width
                        y: bubble.height
                    }
                    PathLine {
                        x: 16
                        y: bubble.height
                    }
                    PathLine {
                        x: 16
                        y: bubble.height * 0.62
                    }
                    PathLine {
                        x: 0
                        y: bubble.height * 0.48
                    }
                    PathLine {
                        x: 16
                        y: bubble.height * 0.34
                    }
                    PathLine {
                        x: 16
                        y: 0
                    }
                }
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.critical ? Theme.ink : Theme.paper
                    strokeColor: root.critical ? Theme.accent : "transparent"
                    strokeWidth: 2
                    startX: 16
                    startY: 0
                    PathLine {
                        x: bubble.width
                        y: 0
                    }
                    PathLine {
                        x: bubble.width
                        y: bubble.height
                    }
                    PathLine {
                        x: 16
                        y: bubble.height
                    }
                    PathLine {
                        x: 16
                        y: bubble.height * 0.62
                    }
                    PathLine {
                        x: 0
                        y: bubble.height * 0.48
                    }
                    PathLine {
                        x: 16
                        y: bubble.height * 0.34
                    }
                    PathLine {
                        x: 16
                        y: 0
                    }
                }
            }

            // Clic en la burbuja = acción por defecto de la app
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const d = (root.n?.actions ?? []).find(a => a.identifier === "default");
                    if (d)
                        d.invoke();
                    Notifs.drop(root.n);
                }
            }

            Column {
                id: bodyCol
                x: 30
                y: 12
                width: parent.width - 46
                spacing: 4

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: (root.n?.summary ?? "").toUpperCase()
                    color: root.critical ? Theme.paper : Theme.ink
                    font {
                        family: "Bebas Neue"
                        pixelSize: 22
                        letterSpacing: 1.5
                    }
                }
                Text {
                    visible: text !== ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    text: root.n?.body ?? ""
                    color: root.critical ? Theme.paper : Theme.ink
                    font {
                        family: "Montserrat"
                        pixelSize: 13
                        weight: Font.Medium
                    }
                }
                Row {
                    visible: root.actions.length > 0
                    topPadding: 4
                    spacing: 6
                    Repeater {
                        model: root.actions
                        delegate: Item {
                            required property var modelData
                            required property int index
                            readonly property color fillC: root.tone === Theme.accent3 ? Theme.accent2 : root.tone
                            width: actT.implicitWidth + 24
                            height: 24
                            Slant {
                                anchors.fill: parent
                                color: index === 0 ? parent.fillC : "transparent"
                                borderWidth: index === 0 ? 0 : 1
                                borderColor: root.critical ? Theme.paper : Theme.ink
                            }
                            Text {
                                id: actT
                                anchors.centerIn: parent
                                text: modelData.text.toUpperCase()
                                color: index === 0 ? Theme.on(parent.fillC) : (root.critical ? Theme.paper : Theme.ink)
                                font {
                                    family: "Bebas Neue"
                                    pixelSize: 15
                                    letterSpacing: 1
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    modelData.invoke();
                                    Notifs.drop(root.n);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Tiempo restante
        Item {
            x: 16
            width: parent.width - 16
            height: 6
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.paper, 0.12)
            }
            SegBar {
                count: 24
                gap: 3
                segH: 6
                segW: Math.floor((parent.width - (count - 1) * gap) / count)
                value: root.fill
                fill: root.tone
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris
import "../config"
import "../lock"   // SkewRect

// Isla central: canción / artista. Controles al pasar el ratón.
// Solo visible si algo suena (se queda 3 s tras pausar, o mientras tengas el ratón encima).
Item {
    id: root

    property MprisPlayer player: null
    property bool light: false   // fondo claro detrás → tinta oscura
    property bool plate: false   // fondo muy variado → placa oscura detrás

    // Prioriza el que está sonando; si no, conserva el último mientras exista
    function pick() {
        const list = Mpris.players.values;
        const playing = list.find(p => p.isPlaying);
        if (playing)
            player = playing;
        else if (player && !list.includes(player))
            player = null;
    }

    readonly property bool playing: player !== null && player.isPlaying
    readonly property bool shown: player !== null && (playing || hover.hovered || linger.running)

    onPlayingChanged: if (!playing)
        linger.restart()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pick();
            if (root.playing)
                root.player.positionChanged();   // refresca la barra de progreso
        }
    }
    Timer {
        id: linger
        interval: 3000
    }

    implicitWidth: row.implicitWidth
    implicitHeight: 40
    width: implicitWidth

    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    HoverHandler {
        id: hover
    }

    // Placa colgando del borde superior (pestaña)
    Shape {
        id: plateShape
        x: -24
        y: -8
        width: root.width + 48
        height: 48
        preferredRendererType: Shape.CurveRenderer
        opacity: root.plate ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        ShapePath {
            fillColor: Qt.alpha(Theme.ink, 0.72)
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine {
                x: plateShape.width
                y: 0
            }
            PathLine {
                x: plateShape.width - 16
                y: plateShape.height
            }
            PathLine {
                x: 16
                y: plateShape.height
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Chip ♪ (parpadea en pausa)
        Item {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 22
            SkewRect {
                anchors.fill: parent
                color: root.playing ? Theme.accent : Theme.surface
            }
            Text {
                anchors.centerIn: parent
                text: root.playing ? "♪" : "❚❚"
                color: root.playing ? Theme.on(Theme.accent) : Theme.telemetry
                font.family: "JetBrains Mono"
                font.pixelSize: root.playing ? 14 : 9
                font.weight: Font.ExtraBold
            }
        }

        Text {
            Layout.maximumWidth: 280
            text: root.player ? (root.player.trackTitle || "Sin título") : ""
            elide: Text.ElideRight
            color: root.light ? Theme.ink : Theme.paper
            font.family: "Montserrat"
            font.pixelSize: 13
            font.weight: Font.ExtraBold
        }

        Text {
            Layout.maximumWidth: 180
            visible: root.player !== null && root.player.trackArtist !== ""
            text: "/ " + (root.player ? root.player.trackArtist.toUpperCase() : "")
            elide: Text.ElideRight
            color: root.light ? Qt.alpha(Theme.ink, 0.7) : Theme.telemetry
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1
        }

        // Controles: se despliegan con hover
        Item {
            Layout.preferredHeight: 22
            Layout.preferredWidth: hover.hovered ? controls.implicitWidth : 0
            clip: true
            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: controls
                spacing: 4

                Repeater {
                    model: [
                        {
                            glyph: "◀◀",
                            act: "prev"
                        },
                        {
                            glyph: root.playing ? "❚❚" : "▶",
                            act: "toggle"
                        },
                        {
                            glyph: "▶▶",
                            act: "next"
                        }
                    ]
                    delegate: Item {
                        id: btn
                        required property var modelData
                        readonly property bool main: modelData.act === "toggle"
                        readonly property bool enabledAct: root.player !== null && (modelData.act === "prev" ? root.player.canGoPrevious : modelData.act === "next" ? root.player.canGoNext : root.player.canTogglePlaying)

                        width: main ? 34 : 28
                        height: 22
                        opacity: enabledAct ? 1 : 0.3

                        SkewRect {
                            anchors.fill: parent
                            color: btnHover.hovered ? Theme.accent : (btn.main ? Theme.paper : Theme.surface)
                        }
                        Text {
                            anchors.centerIn: parent
                            text: btn.modelData.glyph
                            color: btnHover.hovered ? Theme.on(Theme.accent) : (btn.main ? Theme.ink : Theme.paper)
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.weight: Font.ExtraBold
                        }
                        HoverHandler {
                            id: btnHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            enabled: btn.enabledAct
                            onTapped: {
                                const p = root.player;
                                if (btn.modelData.act === "prev")
                                    p.previous();
                                else if (btn.modelData.act === "next")
                                    p.next();
                                else
                                    p.togglePlaying();
                            }
                        }
                    }
                }
            }
        }
    }

    // Progreso
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        height: 2
        visible: root.player !== null && root.player.positionSupported && root.player.length > 0
        width: visible ? root.width * Math.min(1, root.player.position / root.player.length) : 0
        color: Theme.accent
        Behavior on width {
            NumberAnimation {
                duration: 900
            }
        }
    }
}

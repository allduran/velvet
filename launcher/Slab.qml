import Quickshell.Widgets
import QtQuick
import "../config"
import "../components"

Item {
    id: root
    property string key
    property string label
    property string meta
    property string iconSource
    property color tone: Theme.accent
    property bool core: false
    property real s: 1
    property real rot: 0
    property int order: 0
    property real tx: 0          // posición final
    property real ty: 0
    property real ox: 0          // origen de la animación (centro)
    property real oy: 0
    property real pop: 1
    signal clicked

    width: 250
    height: 62
    rotation: rot
    scale: s * pop
    Component.onCompleted: {
        x = tx;
        y = ty;
    }
    onTxChanged: if (!anim.running)
        x = tx
    onTyChanged: if (!anim.running)
        y = ty

    // Sale disparada desde el centro hasta su sitio
    function enter() {
        x = ox;
        y = oy;
        pop = 0.3;
        opacity = 0;
        anim.restart();
    }
    SequentialAnimation {
        id: anim
        PauseAnimation {
            duration: root.order * 35
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "x"
                to: root.tx
                duration: 280
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "y"
                to: root.ty
                duration: 280
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "pop"
                to: 1
                duration: 280
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: 160
            }
        }
    }

    readonly property bool hot: area.containsMouse

    // Sombra dura
    Slant {
        x: 6
        y: 6
        width: parent.width
        height: parent.height
        color: root.tone
    }

    Slant {
        x: root.hot ? -4 : 0
        y: root.hot ? -4 : 0
        Behavior on x {
            NumberAnimation {
                duration: 80
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 80
            }
        }
        width: parent.width
        height: parent.height
        color: root.core ? Theme.paper : Qt.alpha(Theme.ink, 0.95)
        borderWidth: 2
        borderColor: Theme.paper

        Row {
            anchors {
                left: parent.left
                leftMargin: 18
                verticalCenter: parent.verticalCenter
            }
            spacing: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                color: root.tone
                Text {
                    anchors.centerIn: parent
                    text: root.key
                    color: Theme.on(root.tone)
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 16
                        weight: Font.ExtraBold
                    }
                }
            }
            IconImage {
                visible: root.iconSource !== ""
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 24
                source: root.iconSource
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    width: Math.min(implicitWidth, 140)
                    elide: Text.ElideRight
                    text: root.label
                    color: root.core ? Theme.ink : Theme.paper
                    font {
                        family: "Bebas Neue"
                        pixelSize: 28
                        letterSpacing: 2
                    }
                }
                Text {
                    width: Math.min(implicitWidth, 140)
                    elide: Text.ElideRight
                    text: root.meta
                    color: root.core ? Theme.ink : Theme.paper
                    opacity: 0.7
                    font {
                        family: "JetBrains Mono"
                        pixelSize: 9
                        bold: true
                        letterSpacing: 1.5
                    }
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

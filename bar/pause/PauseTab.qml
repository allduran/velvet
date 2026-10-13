import QtQuick
import "../../config"
import "../../components"

Item {
    id: root
    property string label
    property bool active
    property int order
    signal picked
    width: 130
    height: 28
    opacity: 0
    transform: Translate {
        id: tr
    }

    function enter() {
        tr.x = 30;
        opacity = 0;
        anim.restart();
    }
    SequentialAnimation {
        id: anim
        PauseAnimation {
            duration: root.order * 30
        }
        ParallelAnimation {
            NumberAnimation {
                target: tr
                property: "x"
                to: 0
                duration: 160
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: 160
            }
        }
    }

    Slant {
        visible: root.active
        x: box.x + 3
        y: 3
        width: box.width
        height: box.height
        color: Theme.at(root.order)
    }

    Slant {
        id: box
        x: root.active ? 0 : 12
        width: root.active ? 116 : 104
        height: 28
        Behavior on x {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        color: root.active ? Theme.paper : Qt.alpha(Theme.ink, 0.92)
        borderWidth: root.active ? 0 : 1
        borderColor: Qt.alpha(Theme.paper, 0.3)

        Text {
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: root.label
            color: root.active ? Theme.ink : Theme.paper
            font {
                family: "Bebas Neue"
                pixelSize: 17
                letterSpacing: 1.5
            }
        }
        Text {
            visible: root.active
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            text: "▶▶"
            color: Theme.ink
            font {
                family: "JetBrains Mono"
                pixelSize: 8
                bold: true
            }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: if (hovered)
            root.picked()
    }
    TapHandler {
        onTapped: root.picked()
    }
}

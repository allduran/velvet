import Quickshell
import Quickshell.Widgets
import QtQuick
import "../config"
import "../components"

Item {
    id: root
    property var entry
    property bool active
    property int order
    signal picked
    signal launched

    width: active ? 640 : 600
    height: 56
    Behavior on width {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }
    readonly property color tone: Theme.at(order)

    Slant {
        visible: root.active
        x: 6
        y: 6
        width: parent.width
        height: parent.height
        color: root.tone
    }
    Slant {
        anchors.fill: parent
        color: root.active ? Theme.paper : Qt.alpha(Theme.ink, 0.92)
        borderWidth: 2
        borderColor: root.active ? Theme.paper : Qt.alpha(Theme.paper, 0.3)
    }

    Row {
        anchors {
            left: parent.left
            leftMargin: 20
            verticalCenter: parent.verticalCenter
        }
        spacing: 14
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: chipT.implicitWidth + 14
            height: 18
            color: root.active ? Theme.ink : root.tone
            Text {
                id: chipT
                anchors.centerIn: parent
                text: "APP"
                color: root.active ? Theme.paper : Theme.on(root.tone)
                font {
                    family: "JetBrains Mono"
                    pixelSize: 9
                    weight: Font.ExtraBold
                    letterSpacing: 1
                }
            }
        }
        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 22
            source: Quickshell.iconPath(root.entry?.icon ?? "", "application-x-executable")
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 330)
            elide: Text.ElideRight
            text: (root.entry?.name ?? "").toUpperCase()
            color: root.active ? Theme.ink : Theme.paper
            font {
                family: "Bebas Neue"
                pixelSize: 28
                letterSpacing: 1.5
            }
        }
    }

    Row {
        anchors {
            right: parent.right
            rightMargin: 20
            verticalCenter: parent.verticalCenter
        }
        spacing: 14
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 150)
            elide: Text.ElideRight
            text: (root.entry?.genericName ?? "").toUpperCase()
            color: root.active ? Theme.ink : Theme.paper
            opacity: 0.75
            font {
                family: "JetBrains Mono"
                pixelSize: 10
                bold: true
                letterSpacing: 1
            }
        }
        Text {
            visible: root.active
            anchors.verticalCenter: parent.verticalCenter
            text: "▶▶"
            color: Theme.ink
            font {
                family: "JetBrains Mono"
                pixelSize: 12
                weight: Font.ExtraBold
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.picked()
        onClicked: root.launched()
    }
}

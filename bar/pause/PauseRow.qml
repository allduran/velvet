import Quickshell.Widgets
import QtQuick
import "../../config"

Item {
    id: root
    property string label
    property string meta
    property string iconSource
    property bool marked: false
    property bool danger: false
    signal clicked
    signal rightClicked
    width: parent ? parent.width : 0
    height: 28
    opacity: enabled ? 1 : 0.4

    readonly property bool hot: area.containsMouse
    readonly property color fg: hot ? Theme.ink : danger ? Theme.accent : Theme.paper

    Rectangle {
        x: root.hot ? 4 : 0
        Behavior on x {
            NumberAnimation {
                duration: 80
            }
        }
        width: parent.width - 4
        height: parent.height
        color: root.hot ? Theme.paper : root.marked ? Qt.alpha(Theme.paper, 0.08) : "transparent"

        Rectangle {
            visible: root.marked || root.hot
            width: 2
            height: parent.height
            color: root.hot ? Theme.accent : Theme.accent2
        }

        Row {
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 8
            IconImage {
                visible: root.iconSource !== ""
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 14
                source: root.iconSource
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.width - 110)
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                text: root.label
                color: root.fg
                font {
                    family: "Bebas Neue"
                    pixelSize: 16
                    letterSpacing: 1
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.meta
                color: root.fg
                opacity: 0.7
                font {
                    family: "JetBrains Mono"
                    pixelSize: 8
                    bold: true
                    letterSpacing: 1
                }
            }
        }

        Text {
            visible: root.hot
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            text: ">>"
            color: Theme.ink
            font {
                family: "JetBrains Mono"
                pixelSize: 9
                bold: true
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}

import QtQuick
import "../config"

Item {
    id: root
    property int count: 12
    property real value: 0
    property int segW: 22
    property int segH: 18
    property int gap: 4
    property color fill: Theme.paper
    property bool interactive: false
    signal moved(real v)
    implicitWidth: count * segW + (count - 1) * gap
    implicitHeight: segH

    Row {
        spacing: root.gap
        Repeater {
            model: root.count
            Slant {
                required property int index
                width: root.segW
                height: root.segH
                color: index < Math.round(root.value * root.count) ? root.fill : Qt.alpha(Theme.paper, 0.15)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        function set(x) {
            root.moved(Math.max(0, Math.min(1, x / width)));
        }
        onPressed: m => set(m.x)
        onPositionChanged: m => {
            if (pressed)
                set(m.x);
        }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}

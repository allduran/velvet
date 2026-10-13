import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../../config"

Column {
    id: root
    spacing: 2
    signal done

    property var openItem: null
    property var menuStack: []
    onVisibleChanged: if (!visible) {
        openItem = null;
        menuStack = [];
    }

    function iconFor(icon) {
        if (!icon.includes("?path="))
            return icon;
        const [name, path] = icon.split("?path=");
        return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
    }
    function nameOf(item) {
        return item.title || (item.tooltipTitle || "").split("\n")[0] || item.id;
    }
    QsMenuOpener {
        id: opener
        menu: root.menuStack.length > 0 ? root.menuStack[root.menuStack.length - 1] : (root.openItem ? root.openItem.menu : null)
    }

    // Lista de apps
    Text {
        visible: root.openItem === null && SystemTray.items.values.length === 0
        text: "SIN APPS EN SEGUNDO PLANO"
        color: Theme.telemetry
        font {
            family: "JetBrains Mono"
            pixelSize: 9
            bold: true
            letterSpacing: 1.5
        }
    }
    Repeater {
        model: SystemTray.items
        delegate: PauseRow {
            required property SystemTrayItem modelData
            visible: root.openItem === null
            iconSource: root.iconFor(modelData.icon)
            label: root.nameOf(modelData)
            meta: modelData.hasMenu ? "CLIC DCHO · MENÚ" : ""
            onClicked: {
                if (modelData.onlyMenu && modelData.hasMenu) {
                    root.openItem = modelData;
                    return;
                }
                root.done();
                modelData.activate();
            }
            onRightClicked: if (modelData.hasMenu)
                root.openItem = modelData
        }
    }

    // Menú de la app
    PauseRow {
        visible: root.openItem !== null
        label: "← " + (root.openItem ? root.nameOf(root.openItem) : "")
        onClicked: {
            if (root.menuStack.length > 0)
                root.menuStack = root.menuStack.slice(0, -1);
            else
                root.openItem = null;
        }
    }
    Repeater {
        model: opener.children
        delegate: Item {
            required property QsMenuEntry modelData
            visible: root.openItem !== null
            width: root.width
            height: modelData.isSeparator ? 7 : 28

            Rectangle {
                visible: modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                color: Qt.alpha(Theme.paper, 0.15)
            }
            PauseRow {
                visible: !modelData.isSeparator
                enabled: modelData.enabled
                iconSource: modelData.icon
                label: modelData.text.replace(/_/g, "") + (modelData.hasChildren ? "  ›" : "")
                onClicked: {
                    if (modelData.hasChildren) {
                        root.menuStack = [...root.menuStack, modelData];
                        return;
                    }
                    modelData.triggered();
                    root.done();
                }
            }
        }
    }
}

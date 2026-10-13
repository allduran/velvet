pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property int unread: 0
    property bool dnd: false              // No molestar: solo pasan las críticas
    property var popups: []               // burbujas visibles ahora
    property var banner: null             // notificación crítica en la banda
    readonly property var all: server.trackedNotifications.values   // historial

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        bodyMarkupSupported: false

        onNotification: n => {
            n.tracked = true;                       // se queda en el historial
            root.unread++;
            n.closed.connect(() => root.drop(n));

            const critical = n.urgency === NotificationUrgency.Critical;
            if (root.dnd && !critical)
                return;

            if (critical) {
                root.banner = n;
                bannerT.restart();
                showLater.n = n;                    // la burbuja aparece al acabar la banda
                showLater.restart();
            } else {
                root.popups = [n, ...root.popups];
            }
        }
    }

    Timer {
        id: bannerT
        interval: 1700
        onTriggered: root.banner = null
    }
    Timer {
        id: showLater
        property var n
        interval: 1700
        onTriggered: root.popups = [n, ...root.popups]
    }

    // Quita la burbuja (sigue en el historial)
    function drop(n) {
        popups = popups.filter(p => p !== n);
    }
    function markRead() {
        unread = 0;
    }
    function clearAll() {
        server.trackedNotifications.values.slice().forEach(n => n.dismiss());
        popups = [];
        unread = 0;
    }
}

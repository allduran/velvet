import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// Lockscreen "Canal robado" (P4 × P5).
// Bloquear: qs -c velvet ipc call lock lock
Scope {
    id: root

    // ⚠ Mientras pruebas: Esc desbloquea sin contraseña. Ponlo a false cuando funcione.
    property bool testMode: false

    property string pw: ""
    property bool busy: false
    property bool failed: false
    property bool success: false

    signal failure

    function lock() {
        pw = "";
        failed = false;
        success = false;
        busy = false;
        sessionLock.locked = true;
    }
    function tryUnlock() {
        if (pw === "" || busy || success)
            return;
        busy = true;
        pam.start();
    }
    function release() {
        sessionLock.locked = false;
        pw = "";
        success = false;
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.lock();
        }
    }

    PamContext {
        id: pam
        configDirectory: "pam"          // relativo a este archivo → lock/pam/
        config: "password.conf"

        onPamMessage: {
            if (responseRequired)
                respond(root.pw);
        }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.success = true;
                unlockDelay.restart();
            } else {
                root.pw = "";
                root.failed = true;
                root.failure();
                failReset.restart();
            }
        }
    }

    // Deja ver "¡BIENVENIDO!" antes de soltar el lock
    Timer {
        id: unlockDelay
        interval: 900
        onTriggered: root.release()
    }
    Timer {
        id: failReset
        interval: 900
        onTriggered: root.failed = false
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            color: "#E60012"
            LockSurface {
                anchors.fill: parent
                ctx: root
            }
        }
    }
}

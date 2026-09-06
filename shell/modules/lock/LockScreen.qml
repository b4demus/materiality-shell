pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/config"
import "root:/services"

// Material You session lock. Real Wayland session lock (ext-session-lock); the
// UI lives in LockContent so it can also be previewed in a normal window.
Scope {
    id: root

    // Bridge logind Lock/Unlock + PrepareForSleep to Bus.locked, so
    // `loginctl lock-session` and lock-on-suspend work too.
    Process {
        id: bridge
        command: [`${Quickshell.env("HOME")}/.local/bin/expressive-lock`, "monitor"]
    }
    Component.onCompleted: bridge.running = true

    WlSessionLock {
        id: lock
        locked: Bus.locked

        surface: WlSessionLockSurface {
            id: surf
            color: Colors.background

            LockContent {
                anchors.fill: parent
                active: lock.locked
                onUnlocked: Bus.locked = false
            }
        }
    }
}

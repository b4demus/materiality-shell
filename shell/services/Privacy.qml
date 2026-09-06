pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// Privacy — the camera / microphone kill-switches, GNOME-style.
//
// Microphone: the default PipeWire source is muted, so every application that
//   opens it captures silence. Instant and in-process (via Audio / PipeWire),
//   also reachable from a key bind through `expressive-privacy mic toggle`.
//
// Camera: there is no user-space capability to revoke, so `expressive-privacy`
//   drops the permission bits on the /dev/video* nodes. That needs the shell to
//   be able to chmod them; when it can't, `cameraEnforceable` is false and the
//   settings page says the preference is stored but not enforced. In this VM
//   there is no camera device at all.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // ---- microphone -----------------------------------------------------
    // Live truth is the PipeWire source mute; the stored pref just mirrors it.
    readonly property bool micReady: Audio.micReady
    readonly property bool micEnabled: Audio.micReady && !Audio.micMuted

    function setMic(on) {
        if (!Audio.micReady) return
        Audio.source.audio.muted = !on
        Settings.set("privacy.microphone", !!on)
    }
    function toggleMic() { setMic(!root.micEnabled) }

    Connections {
        target: Audio
        function onMicMutedChanged() {
            if (Audio.micReady)
                Settings.set("privacy.microphone", !Audio.micMuted)
        }
    }

    // ---- camera --------------------------------------------------------
    readonly property bool cameraAllowed: Settings.val("privacy.camera", true)
    property int cameraDeviceCount: 0
    property bool cameraPresent: cameraDeviceCount > 0
    property bool cameraEnforceable: false   // can we actually chmod the nodes?

    function _run(args) {
        cameraProc.command = args
        cameraProc.running = true
    }

    function setCamera(allowed) {
        Settings.set("privacy.camera", !!allowed)
        _run([Files.bin("expressive-privacy"), "camera", allowed ? "allow" : "block"])
        statusTimer.restart()
    }
    function toggleCamera() { setCamera(!root.cameraAllowed) }

    function refreshCamera() { cameraStatusProc.running = true }

    Process {
        id: cameraStatusProc
        stdout: StdioCollector {
            onStreamFinished: {
                // "<count> <ok|noperm|nodev>"
                const parts = text.trim().split(/\s+/)
                root.cameraDeviceCount = parseInt(parts[0]) || 0
                root.cameraEnforceable = parts[1] === "ok"
            }
        }
        Component.onCompleted: command = [Files.bin("expressive-privacy"), "camera", "status"]
    }

    Process { id: cameraProc; onExited: statusTimer.restart() }
    Timer { id: statusTimer; interval: 400; onTriggered: root.refreshCamera() }

    // Re-assert the stored camera choice whenever it changes or the shell starts.
    Connections {
        target: Settings
        function onChanged(path, value) {
            if (path === "*" || String(path).startsWith("privacy.camera"))
                applyTimer.restart()
        }
    }
    Timer { id: applyTimer; interval: 200
            onTriggered: root._run([Files.bin("expressive-privacy"), "camera", "apply"]) }

    Component.onCompleted: {
        _run([Files.bin("expressive-privacy"), "camera", "apply"])
        refreshCamera()
    }
}

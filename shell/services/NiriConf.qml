pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// NiriManager — the settings store's mirror of ~/.config/niri/config.kdl.
//
// Reading and writing both go through `expressive-niri`, which edits the KDL
// surgically (comments and hand-written blocks survive) and refuses to install
// a file that `niri validate` rejects. niri hot-reloads on write, so gaps,
// borders, input and window rules all apply live — no compositor restart.
//
// On first run the compositor's config is authoritative: its values are pulled
// into the settings store so the UI opens showing the real desktop. After that
// the store leads and this pushes.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    property var values: ({})
    property bool loaded: false
    property bool busy: false
    property string lastError: ""

    // Settings paths that map onto niri's config, and how.
    readonly property var mapping: ({
        "niri.gapsInner":            "gaps",
        "niri.borderWidth":          "borderWidth",
        "niri.borderEnabled":        "borderEnabled",
        "niri.focusRingWidth":       "focusRingWidth",
        "niri.focusRingEnabled":     "focusRingEnabled",
        "niri.cornerRadius":         "cornerRadius",
        "niri.focusFollowsMouse":    "focusFollowsMouse",
        "niri.centerFocusedColumn":  "centerFocusedColumn",
        "niri.defaultColumnWidth":   "defaultColumnWidth",
        "niri.presetColumnWidths":   "presetColumnWidths",
        "niri.animationsEnabled":    "animationsEnabled",
        "niri.animationSlowdown":    "animationSlowdown",
        "niri.gapsOuter":            "strutTop",
        "input.keyboard.layouts":    "kbLayout",
        "input.keyboard.variants":   "kbVariant",
        "input.keyboard.options":    "kbOptions",
        "input.keyboard.repeatDelay": "kbRepeatDelay",
        "input.keyboard.repeatRate": "kbRepeatRate",
        "input.keyboard.numlockOnBoot": "numlock",
        "input.mouse.speed":         "mouseSpeed",
        "input.mouse.accelProfile":  "mouseAccelProfile",
        "input.mouse.naturalScroll": "mouseNatural",
        "input.mouse.middleEmulation": "mouseMiddleEmulation",
        "input.touchpad.enabled":    "touchpadEnabled",
        "input.touchpad.speed":      "touchpadSpeed",
        "input.touchpad.accelProfile": "touchpadAccelProfile",
        "input.touchpad.naturalScroll": "touchpadNatural",
        "input.touchpad.tap":        "touchpadTap",
        "input.touchpad.dwt":        "touchpadDwt",
        "input.touchpad.scrollMethod": "touchpadScrollMethod",
        "input.touchpad.clickMethod": "touchpadClickMethod"
    })

    // Everything here applies without a niri restart; kept as an explicit list
    // so the UI can honestly badge anything that doesn't.
    readonly property var needsRestart: ["input.keyboard.numlockOnBoot"]

    function refresh() { getProc.running = true }

    // Push the whole mapped surface at once. Cheap (one process) and keeps the
    // KDL in sync even if the store was edited outside the app.
    function push() {
        if (busy) return
        const patch = {}
        for (const path in mapping) {
            const v = Settings.val(path, null)
            if (v !== null && v !== undefined) patch[mapping[path]] = v
        }
        // Outer gaps live as struts on all four sides.
        const outer = Settings.val("niri.gapsOuter", 0)
        patch.strutTop = outer
        patch.strutBottom = outer
        patch.strutLeft = outer
        patch.strutRight = outer

        busy = true
        setProc.command = [Files.bin("expressive-niri"), "set", JSON.stringify(patch)]
        setProc.running = true
    }

    function pushRules() {
        rulesProc.command = [Files.bin("expressive-niri"), "rules",
                             JSON.stringify(Settings.val("windows.rules", []))]
        rulesProc.running = true
    }

    function pushOutputs(map) {
        outProc.command = [Files.bin("expressive-niri"), "outputs", JSON.stringify(map)]
        outProc.running = true
    }

    // Seed the store from the live compositor config (first run only).
    function seedFromNiri() {
        const patch = {}
        for (const path in mapping) {
            const v = root.values[mapping[path]]
            if (v !== null && v !== undefined) patch[path] = v
        }
        // No struts in the config means no outer gaps — record that explicitly
        // so a later push doesn't introduce them out of nowhere.
        patch["niri.gapsOuter"] = (root.values.strutTop === null
                                   || root.values.strutTop === undefined)
                                  ? 0 : root.values.strutTop
        patch["niri._seeded"] = true
        Settings.patch(patch)
    }

    function action(args) {
        actProc.command = ["niri", "msg", "action"].concat(args)
        actProc.running = true
    }

    Component.onCompleted: refresh()

    Process {
        id: getProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.values = JSON.parse(text) } catch (e) { root.values = {} }
                root.loaded = true
                if (!Settings.val("niri._seeded", false)) root.seedFromNiri()
            }
        }
        onExited: if (!root.loaded) root.loaded = true
        Component.onCompleted: command = [Files.bin("expressive-niri"), "get"]
    }

    Process {
        id: setProc
        stderr: StdioCollector {
            onStreamFinished: root.lastError = text.trim()
        }
        onExited: (code) => {
            root.busy = false
            if (code === 0) root.lastError = ""
            root.refresh()
        }
    }

    Process { id: rulesProc; onExited: root.refresh() }
    Process { id: outProc; onExited: root.refresh() }
    Process { id: actProc }

    // Coalesce bursts of slider movement into a single config write.
    Timer {
        id: pushTimer
        interval: 350
        onTriggered: root.push()
    }

    Connections {
        target: Settings
        function onChanged(path, value) {
            if (path === "*") return
            if (path === "windows.rules") { root.pushRules(); return }
            if (path.startsWith("niri.") || path.startsWith("input."))
                pushTimer.restart()
        }
    }
}

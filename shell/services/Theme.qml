pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// Colour-scheme selection for the shell.
//
//   dynamic   -> Material You generated live from the wallpaper by matugen
//   auto      -> the curated scheme closest to the current wallpaper
//   <name>    -> a curated scheme from theme/schemes/<name>.json
//
// The heavy lifting lives in ~/.local/bin/expressive-theme, which writes
// ~/.local/state/expressive/colors.json (watched by config/Colors.qml) and
// persists the choice to ~/.local/state/expressive/scheme (watched here).
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string bin: `${home}/.local/bin/expressive-theme`

    // Synthetic modes first, then the curated schemes discovered on disk.
    readonly property var builtins: [
        { name: "dynamic", label: "Dynamic" },
        { name: "auto", label: "Auto" },
    ]
    property var curated: []
    readonly property var schemes: builtins.concat(curated)

    property string current: "dynamic"
    property bool busy: false

    // True while the palette is being driven by a hand-picked accent colour
    // rather than the wallpaper.
    readonly property bool accentMode: current.indexOf("accent:") === 0
    readonly property string accentColor: accentMode
        ? current.substring(7) : Settings.val("appearance.accent", "#d0bcff")

    // A short palette of pleasant seeds for the accent picker.
    readonly property var accentSwatches: [
        "#6750a4", "#3f7fd0", "#2e7d6b", "#4f8a3d", "#b08900",
        "#c2591f", "#c0392b", "#b13a76", "#7a4fbf", "#5c6470"
    ]

    function labelFor(name) {
        if (String(name).indexOf("accent:") === 0) return "Custom accent"
        for (const s of schemes)
            if (s.name === name)
                return s.label
        return name
    }

    function setScheme(name) {
        if (busy || !name) return
        busy = true
        applyProc.command = [root.bin, name]
        applyProc.running = true
    }

    function setAccent(hex) {
        Settings.set("appearance.accent", hex)
        Settings.set("appearance.dynamicColors", false)
    }

    // Re-derive the palette from whatever the settings store now says the
    // source of truth is: the wallpaper, or a hand-picked accent.
    function applyFromSettings() {
        const dynamic = Settings.val("appearance.dynamicColors", true)
        if (dynamic) {
            if (accentMode) setScheme("dynamic")
        } else {
            const hex = Settings.val("appearance.accent", "#d0bcff")
            setScheme("accent:" + hex)
        }
    }

    Timer { id: applyTimer; interval: 250; onTriggered: root.applyFromSettings() }

    Connections {
        target: Settings
        function onChanged(path, value) {
            if (path === "appearance.dynamicColors" || path === "appearance.accent")
                applyTimer.restart()
        }
    }

    // Re-fan the *current* scheme to the terminal / GTK / Qt configs whenever
    // the resolved light/dark flips (the shell's own colours already follow it
    // through colors.json). `expressive-theme` with no argument re-applies the
    // persisted scheme, reading the fresh light/dark from the settings store.
    function reapply() {
        if (busy) { modeTimer.restart(); return }
        busy = true
        applyProc.command = [root.bin]
        applyProc.running = true
    }
    Timer { id: modeTimer; interval: 200; onTriggered: root.reapply() }
    Connections {
        target: Colors
        function onDarkChanged() { modeTimer.restart() }
    }

    Component.onCompleted: listProc.running = true

    Process {
        id: listProc
        command: [root.bin, "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = text.trim().split("\n").filter(l => l.length > 0)
                root.curated = rows.map(l => {
                    const parts = l.split("\t")
                    return { name: parts[0], label: parts[1] || parts[0] }
                })
            }
        }
    }

    Process {
        id: applyProc
        onExited: root.busy = false
    }

    FileView {
        id: stateFile
        path: `${root.home}/.local/state/expressive/scheme`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = stateFile.text().trim() || "dynamic"
        onLoadFailed: root.current = "dynamic"
    }
}

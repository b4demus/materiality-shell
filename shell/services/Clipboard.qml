pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history for the bar widget. The actual watching/storage is done by
// `expressive-clip` (spawn-at-startup); this just reads the index it maintains
// and can push an entry back onto the clipboard.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string bin: `${home}/.local/bin/expressive-clip`
    readonly property string dir: {
        const xdg = Quickshell.env("XDG_STATE_HOME")
        return `${xdg && xdg.length > 0 ? xdg : home + "/.local/state"}/expressive/clipboard`
    }

    // [{ id, kind: "text" | "image", preview, path }] — newest first, max 15.
    property var entries: []

    function _parse(txt) {
        const out = []
        for (const line of ("" + txt).split("\n")) {
            if (!line) continue
            const a = line.indexOf("\t")
            const b = line.indexOf("\t", a + 1)
            if (a < 0 || b < 0) continue
            out.push({
                id: line.slice(0, a),
                kind: line.slice(a + 1, b),
                preview: line.slice(b + 1),
                path: `${root.dir}/${line.slice(0, a)}.entry`
            })
        }
        return out
    }

    function copy(id) {
        if (!id) return
        copyProc.command = [root.bin, "copy", "" + id]
        copyProc.running = true
    }
    function clear() {
        clearProc.command = [root.bin, "clear"]
        clearProc.running = true
    }

    Process { id: copyProc }
    Process { id: clearProc }

    // Own the clipboard watcher's lifecycle (the `watch` subcommand is a no-op
    // if one is already running, so a reload never doubles it up).
    Process { id: watchProc; command: [root.bin, "watch"] }
    Component.onCompleted: watchProc.running = true

    FileView {
        id: idx
        path: `${root.dir}/index`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.entries = root._parse(idx.text())
        onLoadFailed: root.entries = []
    }
}

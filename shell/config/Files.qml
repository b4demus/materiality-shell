pragma Singleton

import QtQuick
import Quickshell

// Path helpers shared by every manager, so no module hardcodes ~/.local/bin.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string config: `${home}/.config`
    readonly property string stateDir: `${home}/.local/state/expressive`
    readonly property string dataDir: `${home}/.local/share/expressive`
    readonly property string shellDir: `${home}/.config/quickshell/expressive`
    readonly property string binDir: `${home}/.local/bin`

    function bin(name) { return `${root.binDir}/${name}` }

    // "/home/u/Pictures/a.png" -> "a"
    function baseName(path) {
        const f = String(path).split("/").pop()
        const dot = f.lastIndexOf(".")
        return dot > 0 ? f.substring(0, dot) : f
    }
    function fileName(path) { return String(path).split("/").pop() }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// WallpaperManager — the catalog, per-monitor assignment, slideshow, and the
// hand-off to the palette engine.
//
// `~/.local/state/expressive/wallpaper` stays the single "primary" wallpaper,
// because that is what expressive-wall feeds to matugen to derive the Material
// You palette. Per-output overrides live in the settings store and only affect
// what each Background surface paints.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string catalogDir: `${home}/.local/share/expressive/wallpapers`

    property string path: ""
    readonly property url source: path ? Qt.resolvedUrl("file://" + path) : ""
    readonly property bool hasWallpaper: path.length > 0

    property var list: []          // resolved absolute paths in the catalog
    property bool busy: false

    // ---- per-output resolution -------------------------------------------
    readonly property bool perOutput: Settings.val("wallpaper.mode", "same") === "per-output"
    readonly property var overrides: Settings.val("wallpaper.perOutput", {})

    function pathFor(outputName) {
        if (perOutput && outputName && overrides[outputName]) return overrides[outputName]
        return root.path
    }
    function sourceFor(outputName) {
        const p = pathFor(outputName)
        return p ? Qt.resolvedUrl("file://" + p) : ""
    }

    // ---- scaling ----------------------------------------------------------
    readonly property string scaling: Settings.val("wallpaper.scaling", "fill")
    readonly property var scalingModes: [
        { value: "fill",    label: "Fill",    icon: "crop_free",  hint: "Cover the screen, cropping the edges" },
        { value: "fit",     label: "Fit",     icon: "fit_screen", hint: "Show the whole image, letterboxed" },
        { value: "center",  label: "Center",  icon: "center_focus_weak", hint: "Original size, centred" },
        { value: "stretch", label: "Stretch", icon: "aspect_ratio", hint: "Distort to fill exactly" },
        { value: "tile",    label: "Tile",    icon: "grid_on",    hint: "Repeat across the screen" }
    ]

    function fillModeFor(mode) {
        switch (mode || root.scaling) {
        case "fit":     return Image.PreserveAspectFit
        case "center":  return Image.Pad
        case "stretch": return Image.Stretch
        case "tile":    return Image.Tile
        default:        return Image.PreserveAspectCrop
        }
    }

    // ---- favourites & collections ----------------------------------------
    readonly property var favorites: Settings.val("wallpaper.favorites", [])
    readonly property var collections: Settings.val("wallpaper.collections", {})
    readonly property var recent: Settings.val("wallpaper.recent", [])

    function isFavorite(p) { return favorites.indexOf(p) >= 0 }

    function toggleFavorite(p) {
        const next = favorites.slice()
        const i = next.indexOf(p)
        if (i >= 0) next.splice(i, 1)
        else next.push(p)
        Settings.set("wallpaper.favorites", next)
    }

    function collectionNames() { return Object.keys(collections).sort() }

    function collectionOf(name) { return collections[name] || [] }

    function createCollection(name) {
        if (!name || collections[name]) return
        const next = Object.assign({}, collections)
        next[name] = []
        Settings.set("wallpaper.collections", next)
    }

    function deleteCollection(name) {
        const next = Object.assign({}, collections)
        delete next[name]
        Settings.set("wallpaper.collections", next)
    }

    function setInCollection(name, p, member) {
        if (!collections[name]) return
        const next = Object.assign({}, collections)
        const arr = (next[name] || []).slice()
        const i = arr.indexOf(p)
        if (member && i < 0) arr.push(p)
        if (!member && i >= 0) arr.splice(i, 1)
        next[name] = arr
        Settings.set("wallpaper.collections", next)
    }

    function _pushRecent(p) {
        const next = recent.filter(x => x !== p)
        next.unshift(p)
        Settings.set("wallpaper.recent", next.slice(0, 12))
    }

    // ---- setting the wallpaper -------------------------------------------
    // Assigning to one output only repaints that surface; assigning globally
    // also reruns the palette engine, because the theme follows one image.
    function set(p, outputName) {
        if (!p) return
        if (outputName && perOutput) {
            const next = Object.assign({}, overrides)
            next[outputName] = p
            Settings.set("wallpaper.perOutput", next)
            _pushRecent(p)
            fileProc.command = [Files.bin("expressive-wall"), "--catalog-only", p]
            fileProc.running = true
            return
        }
        if (busy) return
        busy = true
        _pushRecent(p)
        setProc.command = [Files.bin("expressive-wall"), p]
        setProc.running = true
    }

    function clearOverride(outputName) {
        const next = Object.assign({}, overrides)
        delete next[outputName]
        Settings.set("wallpaper.perOutput", next)
    }

    function browse(outputName) {
        if (busy) return
        root._pendingOutput = outputName || ""
        pickProc.running = true
    }
    property string _pendingOutput: ""

    function remove(resolvedPath) {
        if (!resolvedPath) return
        rmProc.command = ["sh", "-c",
            'for f in "$1"/*; do [ -e "$f" ] || continue; ' +
            '[ "$(realpath -e -- "$f" 2>/dev/null)" = "$2" ] && rm -f -- "$f"; done',
            "sh", root.catalogDir, resolvedPath]
        rmProc.running = true
        if (isFavorite(resolvedPath)) toggleFavorite(resolvedPath)
    }

    function rescan() { scanProc.running = true }

    Component.onCompleted: rescan()

    Process {
        id: setProc
        onExited: { root.busy = false; root.rescan() }
    }
    Process { id: fileProc; onExited: root.rescan() }
    Process { id: rmProc; onExited: root.rescan() }

    // Desktop file picker -> set()
    Process {
        id: pickProc
        command: ["sh", "-c",
            'command -v zenity >/dev/null && exec zenity --file-selection ' +
            '--title="Choose a wallpaper" ' +
            '--file-filter="Images | *.png *.jpg *.jpeg *.webp *.bmp *.tiff" ' +
            '--file-filter="All files | *"; ' +
            'command -v kdialog >/dev/null && exec kdialog --getopenfilename "$HOME" ' +
            '"image/png image/jpeg image/webp image/bmp"; ' +
            'echo __NO_PICKER__ >&2']
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0) root.set(p, root._pendingOutput)
                root._pendingOutput = ""
            }
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c",
            'D="$1"; mkdir -p "$D"; ' +
            'find -L "$D" -maxdepth 1 -type f ' +
            '\\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" ' +
            '-o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.tiff" \\) ' +
            '-exec realpath -e {} \\; 2>/dev/null | sort -u',
            "sh", root.catalogDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = text.trim().split("\n").filter(s => s.length > 0)
            }
        }
    }

    FileView {
        id: file
        path: `${root.home}/.local/state/expressive/wallpaper`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.path = file.text().trim(); root.rescan() }
        onLoadFailed: root.path = ""
    }

    // ---- slideshow --------------------------------------------------------
    readonly property bool slideshow: Settings.val("wallpaper.slideshow.enabled", false)
    readonly property int slideshowInterval: Settings.val("wallpaper.slideshow.intervalSec", 900)
    readonly property bool slideshowRandom: Settings.val("wallpaper.slideshow.random", true)
    readonly property string slideshowCollection: Settings.val("wallpaper.slideshow.collection", "")

    function slideshowPool() {
        const c = slideshowCollection
        const pool = c && collections[c] ? collections[c] : root.list
        return (pool || []).filter(p => p && p.length > 0)
    }

    function advance() {
        const pool = slideshowPool()
        if (pool.length === 0) return
        if (pool.length === 1) { if (pool[0] !== root.path) set(pool[0]); return }
        let next
        if (slideshowRandom) {
            do { next = pool[Math.floor(Math.random() * pool.length)] }
            while (next === root.path)
        } else {
            const i = pool.indexOf(root.path)
            next = pool[(i + 1) % pool.length]
        }
        set(next)
    }

    Timer {
        interval: Math.max(30, root.slideshowInterval) * 1000
        repeat: true
        running: root.slideshow && !root.busy
        onTriggered: root.advance()
    }
}

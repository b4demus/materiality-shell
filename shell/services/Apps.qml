pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// ApplicationManager — default handlers and session autostart.
//
// Defaults are real XDG defaults (xdg-mime / mimeapps.list), so they apply to
// every app on the system, not just this shell. Autostart is the standard
// ~/.config/autostart directory, which niri --session honours through
// xdg-desktop-autostart.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    readonly property var applications: DesktopEntries.applications

    // role -> the mime types that actually decide it
    readonly property var roles: [
        { key: "browser",     label: "Web browser",  icon: "public",
          mimes: ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"] },
        { key: "fileManager", label: "File manager", icon: "folder",
          mimes: ["inode/directory"] },
        { key: "editor",      label: "Text editor",  icon: "edit_document",
          mimes: ["text/plain"] },
        { key: "mediaPlayer", label: "Media player", icon: "play_circle",
          mimes: ["video/mp4", "audio/mpeg", "audio/flac"] },
        { key: "imageViewer", label: "Image viewer", icon: "image",
          mimes: ["image/png", "image/jpeg"] }
    ]

    // Roles the shell itself resolves — no mime type involved.
    readonly property var shellRoles: [
        { key: "terminal",   label: "Terminal",   icon: "terminal" },
        { key: "screenshot", label: "Screenshots", icon: "screenshot" }
    ]

    property var defaults: ({})     // { role: "firefox.desktop" }
    property bool loaded: false

    // Sorted, de-noised app list for the pickers.
    readonly property var visibleApps: {
        const out = []
        for (const a of (applications && applications.values !== undefined
                         ? applications.values : applications) || [])
            if (a && !a.noDisplay) out.push(a)
        out.sort((a, b) => String(a.name).localeCompare(String(b.name)))
        return out
    }

    function entryById(id) {
        if (!id) return null
        for (const a of visibleApps)
            if (a.id === id || a.id === id.replace(/\.desktop$/, "")) return a
        return null
    }

    function nameFor(id) {
        const e = entryById(id)
        return e ? e.name : (id ? String(id).replace(/\.desktop$/, "") : "Not set")
    }

    function iconFor(id) {
        const e = entryById(id)
        return e ? e.icon : ""
    }

    function roleFor(key) {
        for (const r of roles) if (r.key === key) return r
        return null
    }

    // Setting a default writes every mime type the role covers, so "browser"
    // really means http, https and html — not just one of them.
    function setDefault(roleKey, desktopId) {
        const r = roleFor(roleKey)
        if (!r) { Settings.set("apps." + roleKey, desktopId); return }
        const id = desktopId.endsWith(".desktop") ? desktopId : desktopId + ".desktop"
        setProc.command = ["xdg-mime", "default", id].concat(r.mimes)
        setProc.running = true
        Settings.set("apps." + roleKey, id)
    }

    function refresh() { queryProc.running = true }

    Component.onCompleted: {
        refresh()
        refreshAutostart()
    }

    Process { id: setProc; onExited: root.refresh() }

    Process {
        id: queryProc
        command: ["sh", "-c",
            'for m in x-scheme-handler/https inode/directory text/plain video/mp4 image/png; do ' +
            'printf "%s\\t%s\\n" "$m" "$(xdg-mime query default "$m" 2>/dev/null | head -n1)"; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const byMime = {}
                for (const line of text.trim().split("\n")) {
                    const p = line.split("\t")
                    if (p.length >= 2 && p[1]) byMime[p[0]] = p[1].trim()
                }
                root.defaults = {
                    browser: byMime["x-scheme-handler/https"] || "",
                    fileManager: byMime["inode/directory"] || "",
                    editor: byMime["text/plain"] || "",
                    mediaPlayer: byMime["video/mp4"] || "",
                    imageViewer: byMime["image/png"] || ""
                }
                root.loaded = true
            }
        }
    }

    // ---- autostart --------------------------------------------------------
    // [{ file, name, exec, icon, enabled }]
    property var autostart: []

    function refreshAutostart() { autoProc.running = true }

    function addAutostart(desktopId) {
        const e = entryById(desktopId)
        if (!e) return
        writeAutostart(e.id, e.name, e.execString || e.command.join(" "), e.icon || "")
    }

    function addAutostartCommand(name, exec) {
        writeAutostart(name.toLowerCase().replace(/[^a-z0-9]+/g, "-"), name, exec, "")
    }

    function writeAutostart(id, name, exec, icon) {
        // Strip the field codes (%U, %f …) — they mean nothing without a caller.
        const cleanExec = String(exec).replace(/%[A-Za-z]/g, "").trim()
        const body = "[Desktop Entry]\n"
            + "Type=Application\n"
            + `Name=${name}\n`
            + `Exec=${cleanExec}\n`
            + (icon ? `Icon=${icon}\n` : "")
            + "X-GNOME-Autostart-enabled=true\n"
            + "X-Expressive-Managed=true\n"
        writeProc.command = ["sh", "-c",
            'mkdir -p "$HOME/.config/autostart" && printf %s "$2" > "$HOME/.config/autostart/$1.desktop"',
            "sh", id, body]
        writeProc.running = true
    }

    function setAutostartEnabled(file, on) {
        toggleProc.command = ["sh", "-c",
            'f="$1"; v="$2"; ' +
            'if grep -q "^X-GNOME-Autostart-enabled=" "$f"; then ' +
            '  sed -i "s/^X-GNOME-Autostart-enabled=.*/X-GNOME-Autostart-enabled=$v/" "$f"; ' +
            'else printf "X-GNOME-Autostart-enabled=%s\\n" "$v" >> "$f"; fi; ' +
            'if grep -q "^Hidden=" "$f"; then ' +
            '  sed -i "s/^Hidden=.*/Hidden=$([ "$v" = true ] && echo false || echo true)/" "$f"; fi',
            "sh", file, on ? "true" : "false"]
        toggleProc.running = true
    }

    function removeAutostart(file) {
        rmProc.command = ["rm", "-f", file]
        rmProc.running = true
    }

    Process { id: writeProc; onExited: root.refreshAutostart() }
    Process { id: toggleProc; onExited: root.refreshAutostart() }
    Process { id: rmProc; onExited: root.refreshAutostart() }

    Process {
        id: autoProc
        command: ["sh", "-c",
            'D="$HOME/.config/autostart"; mkdir -p "$D"; ' +
            'for f in "$D"/*.desktop; do [ -e "$f" ] || continue; ' +
            'n=$(grep -m1 "^Name=" "$f" | cut -d= -f2-); ' +
            'e=$(grep -m1 "^Exec=" "$f" | cut -d= -f2-); ' +
            'i=$(grep -m1 "^Icon=" "$f" | cut -d= -f2-); ' +
            'h=$(grep -m1 "^Hidden=" "$f" | cut -d= -f2-); ' +
            'a=$(grep -m1 "^X-GNOME-Autostart-enabled=" "$f" | cut -d= -f2-); ' +
            'en=true; [ "$h" = "true" ] && en=false; [ "$a" = "false" ] && en=false; ' +
            'printf "%s\\t%s\\t%s\\t%s\\t%s\\n" "$f" "$n" "$e" "$i" "$en"; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const p = line.split("\t")
                    if (p.length < 5) continue
                    out.push({ file: p[0], name: p[1] || Files.baseName(p[0]),
                               exec: p[2], icon: p[3], enabled: p[4] === "true" })
                }
                out.sort((a, b) => String(a.name).localeCompare(String(b.name)))
                root.autostart = out
            }
        }
    }
}

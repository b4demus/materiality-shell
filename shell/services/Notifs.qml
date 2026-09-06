pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"

// ---------------------------------------------------------------------------
// Notifs — the notification history the control-center panel shows.
//
// NotificationLayer feeds every incoming notification here (even the ones DND
// suppresses on screen); the list is capped at `notifications.historyLimit`
// and persisted so "what came in earlier" survives a shell restart.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // Newest first. Each: { appName, summary, body, time (ms epoch) }
    property var history: []

    // Notifications can arrive before the FileView has read the on-disk history;
    // holding them until then stops an early write from clobbering last session's
    // list.
    property bool _loaded: false
    property var _pending: []

    function _push(entry) {
        const limit = Settings.val("notifications.historyLimit", 100)
        if (limit <= 0) return
        const next = root.history.slice()
        next.unshift({
            appName: entry.appName || "",
            summary: entry.summary || "",
            body: entry.body || "",
            time: entry.time || Date.now()
        })
        root.history = next.slice(0, limit)
    }

    function add(entry) {
        if (!entry) return
        if (!root._loaded) { root._pending.push(entry); return }
        _push(entry)
        _save()
    }

    function _flush() {
        root._loaded = true
        if (root._pending.length > 0) {
            for (const e of root._pending) _push(e)
            root._pending = []
            _save()
        }
    }

    function removeAt(i) {
        if (i < 0 || i >= root.history.length) return
        const next = root.history.slice()
        next.splice(i, 1)
        root.history = next
        _save()
    }

    function clear() {
        root.history = []
        _save()
    }

    // "just now" / "5m" / "3h" / "Mon 14:02"
    function ago(ms) {
        const d = Date.now() - ms
        if (d < 45000) return "just now"
        if (d < 3600000) return Math.round(d / 60000) + "m"
        if (d < 86400000) return Math.round(d / 3600000) + "h"
        return Qt.formatDateTime(new Date(ms), "ddd HH:mm")
    }

    function _save() { file.setText(JSON.stringify(root.history)) }

    FileView {
        id: file
        path: `${root.home}/.local/state/expressive/notifications.json`
        printErrors: false
        onLoaded: {
            try {
                const p = JSON.parse(file.text())
                if (Array.isArray(p))
                    root.history = p.filter(e => e && typeof e.time === "number")
            } catch (e) { /* keep [] */ }
            root._flush()
        }
        onLoadFailed: { root.history = []; root._flush() }
    }
}

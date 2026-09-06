pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Countdown timer + one-shot alarms behind the bar-clock popup.
// State lives here (not in the popup) so it keeps ticking while the popup is
// closed. Alarms persist to ~/.local/state/expressive/alarms.json.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // ---- Countdown timer --------------------------------------------------
    property int timerDuration: 5 * 60      // configured length, seconds
    property int timerRemaining: 0          // seconds left (0 = idle / finished)
    property bool timerRunning: false
    readonly property real timerProgress:
        timerDuration > 0 && timerRemaining > 0 ? timerRemaining / timerDuration : 0

    function timerStart(secs) {
        if (secs !== undefined && secs > 0) {
            timerDuration = Math.round(secs)
            timerRemaining = timerDuration
        }
        if (timerRemaining <= 0)
            timerRemaining = timerDuration
        if (timerRemaining > 0)
            timerRunning = true
    }
    function timerPause() { timerRunning = false }
    function timerToggle() { timerRunning ? timerPause() : timerStart() }
    function timerReset() { timerRunning = false; timerRemaining = timerDuration }

    // Dial the configured length (seconds). Ignored while running so the
    // countdown isn't yanked mid-flight.
    function timerSetDuration(secs) {
        if (timerRunning) return
        timerDuration = Math.max(0, Math.min(99 * 3600 + 59 * 60 + 59, Math.round(secs)))
        timerRemaining = timerDuration
    }

    Timer {
        running: root.timerRunning
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.timerRemaining > 1) {
                root.timerRemaining -= 1
            } else {
                root.timerRunning = false
                root.timerRemaining = 0
                root.notify("Timer", "Time's up")
            }
        }
    }

    // ---- Alarms ---------------------------------------------------------
    // [{ id:Number, hour:Int, minute:Int, enabled:Bool }] — one-shot: an alarm
    // disables itself once it fires.
    property var alarms: []

    function addAlarm(hour, minute) {
        const a = alarms.slice()
        a.push({ id: Date.now(), hour: hour | 0, minute: minute | 0, enabled: true })
        a.sort((x, y) => (x.hour * 60 + x.minute) - (y.hour * 60 + y.minute))
        alarms = a
        _save()
    }
    function removeAlarm(id) { alarms = alarms.filter(a => a.id !== id); _save() }
    function toggleAlarm(id) {
        alarms = alarms.map(a => a.id === id ? ({ id: a.id, hour: a.hour, minute: a.minute, enabled: !a.enabled }) : a)
        _save()
    }

    property string _lastMinute: ""
    Timer {
        running: true
        interval: 2000
        repeat: true
        onTriggered: {
            const now = new Date()
            const key = now.getHours() + ":" + now.getMinutes()
            if (key === root._lastMinute)
                return
            root._lastMinute = key
            let fired = false
            const next = root.alarms.map(al => {
                if (al.enabled && al.hour === now.getHours() && al.minute === now.getMinutes()) {
                    fired = true
                    root.notify("Alarm", root._pad(al.hour) + ":" + root._pad(al.minute))
                    return { id: al.id, hour: al.hour, minute: al.minute, enabled: false }
                }
                return al
            })
            if (fired) { root.alarms = next; root._save() }
        }
    }

    // ---- helpers ------------------------------------------------------
    function _pad(n) { return ("0" + n).slice(-2) }

    function notify(title, body) {
        notifyProc.command = ["notify-send", "-a", "Materiality", "-u", "critical", title, body]
        notifyProc.running = true
        soundProc.running = true
    }

    Process { id: notifyProc }
    Process {
        id: soundProc
        command: ["sh", "-c",
            "canberra-gtk-play -i alarm-clock-elapsed >/dev/null 2>&1 || " +
            "paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga >/dev/null 2>&1 || true"]
    }

    // ---- persistence ------------------------------------------------
    function _save() { alarmFile.setText(JSON.stringify(root.alarms)) }

    FileView {
        id: alarmFile
        path: `${root.home}/.local/state/expressive/alarms.json`
        printErrors: false
        onLoaded: {
            try {
                const p = JSON.parse(alarmFile.text())
                if (Array.isArray(p))
                    root.alarms = p.filter(a => a && typeof a.hour === "number")
            } catch (e) { /* keep [] */ }
        }
        onLoadFailed: root.alarms = []
    }
}

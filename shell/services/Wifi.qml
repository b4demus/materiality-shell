pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ---------------------------------------------------------------------------
// Wi-Fi via NetworkManager (nmcli).
//
// Net.qml stays the small always-on status poller the bar uses; this is the
// heavier interactive surface — scanning, connecting, saved profiles — and only
// polls while the Wi-Fi page is actually on screen (`active`).
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // Set by the Wi-Fi page while it is visible; keeps nmcli quiet otherwise.
    property bool active: false

    property bool radioOn: false
    property bool hasDevice: false
    property string device: ""
    property bool scanning: false
    property bool busy: false
    property string status: ""

    // [{ ssid, signal, security, inUse, saved, rate }]
    property var networks: []
    property var saved: []          // saved connection names

    readonly property var current: {
        for (const n of networks) if (n.inUse) return n
        return null
    }

    function iconFor(signal) {
        if (signal >= 75) return "signal_wifi_4_bar"
        if (signal >= 50) return "network_wifi_3_bar"
        if (signal >= 25) return "network_wifi_2_bar"
        if (signal > 0) return "network_wifi_1_bar"
        return "signal_wifi_0_bar"
    }

    function securityLabel(s) {
        if (!s || s === "--" || s === "") return "Open"
        return s
    }

    function isSaved(ssid) { return root.saved.indexOf(ssid) >= 0 }

    // nmcli -t escapes ':' inside values as '\:' — a naive split mangles SSIDs.
    function splitTerse(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (c === ":") { out.push(cur); cur = "" ; continue }
            cur += c
        }
        out.push(cur)
        return out
    }

    function refresh() {
        listProc.running = true
        savedProc.running = true
        radioProc.running = true
    }

    function scan() {
        if (scanning) return
        scanning = true
        scanProc.running = true
    }

    function setRadio(on) {
        busy = true
        status = on ? "Turning Wi-Fi on…" : "Turning Wi-Fi off…"
        run(["nmcli", "radio", "wifi", on ? "on" : "off"])
    }

    function connect(ssid, password) {
        busy = true
        status = `Connecting to ${ssid}…`
        const cmd = ["nmcli", "device", "wifi", "connect", ssid]
        if (password && password.length > 0) cmd.push("password", password)
        run(cmd)
    }

    function connectSaved(ssid) {
        busy = true
        status = `Connecting to ${ssid}…`
        run(["nmcli", "connection", "up", "id", ssid])
    }

    function disconnect(ssid) {
        busy = true
        status = `Disconnecting from ${ssid}…`
        run(["nmcli", "connection", "down", "id", ssid])
    }

    function forget(ssid) {
        busy = true
        status = `Forgetting ${ssid}…`
        run(["nmcli", "connection", "delete", "id", ssid])
    }

    function run(cmd) {
        actProc.command = cmd
        actProc.running = true
    }

    // Errors from nmcli are the whole story when a password is wrong, so they
    // are surfaced verbatim rather than swallowed.
    signal failed(string message)

    Process {
        id: actProc
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) root.status = text.trim()
        }
        onExited: (code) => {
            root.busy = false
            if (code !== 0) root.failed(root.status || "Operation failed")
            else root.status = ""
            root.refresh()
            Net.refresh()
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: { root.scanning = false; root.refresh() }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: root.radioOn = text.trim() === "enabled"
        }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const parts = root.splitTerse(line)
                    if (parts.length >= 2 && parts[parts.length - 1].indexOf("wireless") >= 0)
                        out.push(parts.slice(0, parts.length - 1).join(":"))
                }
                root.saved = out
            }
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,RATE,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}
                const out = []
                for (const line of text.trim().split("\n")) {
                    if (!line) continue
                    const p = root.splitTerse(line)
                    if (p.length < 5) continue
                    const ssid = p.slice(4).join(":").trim()
                    if (!ssid) continue                     // hidden network
                    const sig = parseInt(p[1]) || 0
                    if (seen[ssid] !== undefined) {         // keep the strongest BSS
                        if (out[seen[ssid]].signal < sig) out[seen[ssid]].signal = sig
                        continue
                    }
                    seen[ssid] = out.length
                    out.push({
                        ssid: ssid,
                        inUse: p[0].trim() === "*",
                        signal: sig,
                        security: p[2].trim(),
                        rate: p[3].trim()
                    })
                }
                out.sort((a, b) => (b.inUse ? 1 : 0) - (a.inUse ? 1 : 0) || b.signal - a.signal)
                root.networks = out
            }
        }
    }

    Process {
        id: devProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const p = root.splitTerse(line)
                    if (p.length >= 2 && p[1] === "wifi") {
                        root.hasDevice = true
                        root.device = p[0]
                        return
                    }
                }
                root.hasDevice = false
            }
        }
    }

    Component.onCompleted: devProc.running = true

    Timer {
        interval: 6000
        repeat: true
        running: root.active && root.hasDevice
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}

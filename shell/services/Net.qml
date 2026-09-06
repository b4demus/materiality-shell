pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Network status via nmcli polling (Quickshell 0.2.x networking module API is
// unstable across builds; nmcli is dependable everywhere NetworkManager runs).
Singleton {
    id: root

    // "wifi" | "ethernet" | "disconnected"
    property string kind: "disconnected"
    property string connection: ""
    property string ssid: ""
    property int signal: 0            // 0..100, wifi only
    property bool hasWifiDevice: false

    readonly property bool online: kind !== "disconnected"

    readonly property string icon: {
        if (kind === "ethernet") return "lan"
        if (kind === "wifi") {
            if (signal >= 75) return "signal_wifi_4_bar"
            if (signal >= 50) return "network_wifi_3_bar"
            if (signal >= 25) return "network_wifi_2_bar"
            if (signal > 0)  return "network_wifi_1_bar"
            return "signal_wifi_0_bar"
        }
        return hasWifiDevice ? "signal_wifi_off" : "wifi_off"
    }

    readonly property string label: {
        if (kind === "wifi") return ssid || connection || "Wi-Fi"
        if (kind === "ethernet") return connection || "Ethernet"
        return "Offline"
    }

    function refresh() { statusProc.running = true }
    function toggleWifi() {
        toggleProc.command = ["nmcli", "radio", "wifi", hasWifiDevice && kind === "wifi" ? "off" : "on"]
        toggleProc.running = true
    }
    Process { id: toggleProc; onExited: statusProc.running = true }

    Timer {
        id: refreshTimer
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let kind = "disconnected", conn = "", wifiDev = false
                for (const raw of text.trim().split("\n")) {
                    if (!raw) continue
                    const parts = raw.split(":")
                    const type = parts[0]
                    const state = parts[1]
                    const cname = parts.slice(2).join(":")
                    if (type === "wifi") wifiDev = true
                    if (state === "connected" && kind === "disconnected") {
                        if (type === "ethernet") { kind = "ethernet"; conn = cname }
                        else if (type === "wifi") { kind = "wifi"; conn = cname }
                    }
                }
                root.hasWifiDevice = wifiDev
                root.kind = kind
                root.connection = conn
                if (kind === "wifi") wifiProc.running = true
                else { root.ssid = ""; root.signal = 0 }
            }
        }
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "device", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const raw of text.trim().split("\n")) {
                    if (!raw.startsWith("*")) continue
                    const parts = raw.split(":")
                    root.signal = parseInt(parts[1]) || 0
                    root.ssid = parts.slice(2).join(":")
                    return
                }
            }
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// ---------------------------------------------------------------------------
// AudioManager — PipeWire / WirePlumber.
//
// Devices and per-application streams come straight from the PipeWire object
// model, so switching the default sink or riding one app's volume happens
// in-process; no pactl round trips.
// ---------------------------------------------------------------------------
Singleton {
    id: root

    // ---- defaults (what the bar and OSD use) ------------------------------
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    readonly property bool micReady: source !== null && source.audio !== null
    readonly property real micVolume: micReady ? source.audio.volume : 0
    readonly property bool micMuted: micReady ? source.audio.muted : false

    function setVolume(v) {
        if (!ready) return
        sink.audio.volume = Math.max(0, Math.min(1.0, v))
    }
    function changeVolume(delta) { setVolume(volume + delta) }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted }

    function setMicVolume(v) {
        if (!micReady) return
        source.audio.volume = Math.max(0, Math.min(1.0, v))
    }
    function toggleMicMute() { if (micReady) source.audio.muted = !source.audio.muted }

    readonly property string icon: {
        if (muted || volume <= 0.001) return "volume_off"
        if (volume < 0.34) return "volume_mute"
        if (volume < 0.67) return "volume_down"
        return "volume_up"
    }

    // ---- device + stream inventory ---------------------------------------
    readonly property var allNodes: {
        const m = Pipewire.nodes
        return !m ? [] : (m.values !== undefined ? m.values : m)
    }

    readonly property var outputs: allNodes.filter(n => n && n.isSink && !n.isStream)
    readonly property var inputs: allNodes.filter(n => n && !n.isSink && !n.isStream
                                                  && n.audio !== null)
    readonly property var streams: allNodes.filter(n => n && n.isStream && n.isSink)

    // PipeWire descriptions are long and repetitive ("Built-in Audio Analog
    // Stereo"); prefer the nickname, fall back to something readable.
    function nodeLabel(n) {
        if (!n) return ""
        return n.nickname || n.description || n.name || "Audio device"
    }

    function streamLabel(n) {
        if (!n) return ""
        const p = n.properties || ({})
        return p["application.name"] || p["media.name"] || n.description || n.name || "Stream"
    }

    function streamIcon(n) {
        const p = (n && n.properties) || ({})
        const role = String(p["media.role"] || "").toLowerCase()
        if (role.indexOf("music") >= 0 || role.indexOf("video") >= 0) return "music_note"
        if (role.indexOf("comm") >= 0) return "call"
        if (role.indexOf("game") >= 0) return "sports_esports"
        return "graphic_eq"
    }

    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }
    function setDefaultSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }

    function setNodeVolume(node, v) {
        if (node && node.audio) node.audio.volume = Math.max(0, Math.min(1.0, v))
    }
    function toggleNodeMute(node) {
        if (node && node.audio) node.audio.muted = !node.audio.muted
    }

    function isDefaultSink(node) { return node && sink && node.id === sink.id }
    function isDefaultSource(node) { return node && source && node.id === source.id }

    // Every node whose audio interface must stay live. Without this the volume
    // and mute of anything but the default device read as zero.
    PwObjectTracker {
        objects: {
            const list = []
            if (root.sink) list.push(root.sink)
            if (root.source) list.push(root.source)
            for (const n of root.outputs) list.push(n)
            for (const n of root.inputs) list.push(n)
            for (const n of root.streams) list.push(n)
            return list
        }
    }
}

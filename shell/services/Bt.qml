pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth over BlueZ. Quickshell's Bluetooth module gives us live adapter and
// device objects, so pairing and connecting are property writes and method
// calls rather than bluetoothctl scraping.
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false

    readonly property var devices: {
        const model = Bluetooth.devices
        return !model ? [] : (model.values !== undefined ? model.values : model)
    }

    readonly property var connectedDevices: devices.filter(d => d && d.connected)
    readonly property var pairedDevices: devices.filter(d => d && (d.paired || d.trusted))
    readonly property var nearbyDevices: devices.filter(d => d && !d.paired && !d.trusted)

    readonly property bool hasConnection: connectedDevices.length > 0
    readonly property string firstName: hasConnection ? connectedDevices[0].name : ""

    readonly property string icon: {
        if (!available || !enabled) return "bluetooth_disabled"
        if (hasConnection) return "bluetooth_connected"
        return "bluetooth"
    }

    // BlueZ device classes map onto a handful of useful glyphs.
    function iconFor(d) {
        const icon = String((d && d.icon) || "").toLowerCase()
        if (icon.indexOf("audio-head") >= 0) return "headphones"
        if (icon.indexOf("audio") >= 0) return "speaker"
        if (icon.indexOf("phone") >= 0) return "smartphone"
        if (icon.indexOf("mouse") >= 0 || icon.indexOf("pointing") >= 0) return "mouse"
        if (icon.indexOf("keyboard") >= 0) return "keyboard"
        if (icon.indexOf("computer") >= 0) return "computer"
        if (icon.indexOf("watch") >= 0) return "watch"
        if (icon.indexOf("printer") >= 0) return "print"
        if (icon.indexOf("camera") >= 0) return "photo_camera"
        if (icon.indexOf("input-gaming") >= 0) return "sports_esports"
        return "bluetooth"
    }

    function stateLabel(d) {
        if (!d) return ""
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
        if (d.connected) return d.batteryAvailable
            ? `Connected · ${Math.round(d.battery * 100)}%` : "Connected"
        if (d.paired || d.trusted) return "Paired"
        return "Available"
    }

    function toggle() { if (adapter) adapter.enabled = !adapter.enabled }
    function setDiscovering(on) { if (adapter) adapter.discovering = on }

    function connectDevice(d) {
        if (!d) return
        if (!d.paired && !d.trusted) d.pair()
        else d.connected = true
    }
    function disconnectDevice(d) { if (d) d.connected = false }
    function forgetDevice(d) { if (d) d.forget() }
    function setTrusted(d, on) { if (d) d.trusted = on }
}

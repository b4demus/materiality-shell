import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Bluetooth"
    subtitle: "Pair and manage devices through BlueZ."
    maxWidth: 860

    // Scanning is expensive and drains batteries, so it only runs while the
    // page is open and the user asked for it.
    Component.onDestruction: if (Bt.adapter) Bt.setDiscovering(false)

    headerActions: [
        MButton {
            icon: Bt.discovering ? "hourglass_empty" : "search"
            label: Bt.discovering ? "Searching…" : "Add device"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            enabled: Bt.available && Bt.enabled
            onClicked: Bt.setDiscovering(!Bt.discovering)
        }
    ]

    MEmptyState {
        width: parent.width
        visible: !Bt.available
        icon: "bluetooth_disabled"
        title: "No Bluetooth adapter"
        message: "BlueZ reports no adapter on this machine. Virtual machines usually "
               + "have none unless a USB controller is passed through."
    }

    MSection {
        width: parent.width
        visible: Bt.available
        title: "Adapter"
        icon: "bluetooth"

        MRow {
            width: parent.width
            icon: Bt.icon
            title: "Bluetooth"
            subtitle: Bt.hasConnection
                      ? `${Bt.connectedDevices.length} device(s) connected`
                      : (Bt.enabled ? "On" : "Off")

            MSwitch {
                checked: Bt.enabled
                onToggled: c => Bt.toggle()
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "visibility"
            title: "Visible to other devices"
            subtitle: "Lets nearby devices find this machine while the page is open"
            enabledRow: Bt.enabled

            MSwitch {
                checked: Bt.adapter ? Bt.adapter.discoverable : false
                enabledSwitch: Bt.enabled
                onToggled: c => { if (Bt.adapter) Bt.adapter.discoverable = c }
            }
        }
    }

    // ---- paired -------------------------------------------------------------
    MSection {
        width: parent.width
        visible: Bt.available && Bt.pairedDevices.length > 0
        title: "Your devices"
        icon: "devices"

        Repeater {
            model: Bt.pairedDevices

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: Bt.iconFor(modelData)
                    title: modelData.name || modelData.address
                    subtitle: Bt.stateLabel(modelData)

                    Row {
                        spacing: Appearance.space.s

                        MButton {
                            label: modelData.connected ? "Disconnect" : "Connect"
                            bg: modelData.connected ? Colors.surfaceContainerHighest
                                                    : Colors.secondaryContainer
                            fg: modelData.connected ? Colors.on.surfaceVariant
                                                    : Colors.on.secondaryContainer
                            hpad: Appearance.space.l
                            onClicked: modelData.connected ? Bt.disconnectDevice(modelData)
                                                           : Bt.connectDevice(modelData)
                        }
                        MButton {
                            icon: "delete"
                            iconSize: 18
                            fg: Colors.error
                            onClicked: {
                                forgetDialog.device = modelData
                                forgetDialog.open = true
                            }
                        }
                    }
                }

                MDivider { width: parent.width; visible: index < Bt.pairedDevices.length - 1 }
            }
        }
    }

    // ---- nearby -------------------------------------------------------------
    MSection {
        width: parent.width
        visible: Bt.available && Bt.enabled
        title: "Nearby"
        icon: "radar"

        Repeater {
            model: Bt.nearbyDevices

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: Bt.iconFor(modelData)
                    title: modelData.name || modelData.address
                    subtitle: modelData.pairing ? "Pairing…" : modelData.address
                    clickable: true
                    onClicked: Bt.connectDevice(modelData)

                    MButton {
                        label: modelData.pairing ? "Cancel" : "Pair"
                        bg: Colors.secondaryContainer
                        fg: Colors.on.secondaryContainer
                        hpad: Appearance.space.l
                        onClicked: modelData.pairing ? modelData.cancelPair()
                                                     : Bt.connectDevice(modelData)
                    }
                }

                MDivider { width: parent.width; visible: index < Bt.nearbyDevices.length - 1 }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Bt.nearbyDevices.length === 0
            icon: "bluetooth_searching"
            title: Bt.discovering ? "Looking for devices…" : "Nothing nearby yet"
            message: Bt.discovering
                     ? "Put the device into pairing mode."
                     : "Hit “Add device” to start scanning."
        }
    }

    MDialog {
        id: forgetDialog
        property var device: null

        title: "Forget this device?"
        message: device ? `${device.name || device.address} will have to be paired again.` : ""
        icon: "delete"
        destructive: true
        confirmText: "Forget"
        onConfirmed: if (device) Bt.forgetDevice(device)
    }
}

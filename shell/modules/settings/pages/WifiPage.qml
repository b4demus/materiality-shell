import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Wi-Fi"
    subtitle: "Networks come from NetworkManager, so anything you connect to here is "
              + "available to the rest of the system too."
    maxWidth: 860

    Component.onCompleted: { Wifi.active = true; Wifi.refresh() }
    Component.onDestruction: Wifi.active = false

    headerActions: [
        MButton {
            icon: Wifi.scanning ? "hourglass_empty" : "refresh"
            label: Wifi.scanning ? "Scanning…" : "Scan"
            bg: Colors.surfaceContainerHigh
            fg: Colors.on.surfaceVariant
            hpad: Appearance.space.l
            enabled: Wifi.radioOn && !Wifi.scanning
            onClicked: Wifi.scan()
        }
    ]

    MEmptyState {
        width: parent.width
        visible: !Wifi.hasDevice
        icon: "wifi_off"
        title: "No Wi-Fi adapter"
        message: "NetworkManager doesn't see a wireless device on this machine. "
               + "In a virtual machine that is normal — the guest usually gets a wired link."
    }

    MSection {
        width: parent.width
        visible: Wifi.hasDevice
        title: "Wireless"
        icon: "wifi"

        MRow {
            width: parent.width
            icon: Wifi.radioOn ? "wifi" : "wifi_off"
            title: "Wi-Fi"
            subtitle: Wifi.current ? `Connected to ${Wifi.current.ssid}`
                      : (Wifi.radioOn ? "On, not connected" : "Off")

            MSwitch {
                checked: Wifi.radioOn
                enabledSwitch: !Wifi.busy
                onToggled: c => Wifi.setRadio(c)
            }
        }
    }

    // ---- the current connection, promoted -----------------------------------
    MSection {
        width: parent.width
        visible: Wifi.hasDevice && Wifi.current !== null
        title: "Connected"
        icon: "check_circle"

        MRow {
            width: parent.width
            icon: Wifi.iconFor(Wifi.current ? Wifi.current.signal : 0)
            title: Wifi.current ? Wifi.current.ssid : ""
            subtitle: Wifi.current
                      ? `${Wifi.securityLabel(Wifi.current.security)} · ${Wifi.current.signal}% signal`
                        + (Wifi.current.rate ? ` · ${Wifi.current.rate}` : "")
                      : ""

            Row {
                spacing: Appearance.space.s
                MButton {
                    label: "Disconnect"
                    bg: Colors.surfaceContainerHighest
                    fg: Colors.on.surfaceVariant
                    hpad: Appearance.space.l
                    enabled: !Wifi.busy
                    onClicked: Wifi.disconnect(Wifi.current.ssid)
                }
                MButton {
                    label: "Forget"
                    fg: Colors.error
                    hpad: Appearance.space.l
                    enabled: !Wifi.busy
                    onClicked: Wifi.forget(Wifi.current.ssid)
                }
            }
        }
    }

    // ---- available networks --------------------------------------------------
    MSection {
        width: parent.width
        visible: Wifi.hasDevice && Wifi.radioOn
        title: "Available networks"
        icon: "radar"

        Repeater {
            model: Wifi.networks.filter(n => !n.inUse)

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: Wifi.iconFor(modelData.signal)
                    title: modelData.ssid
                    subtitle: Wifi.securityLabel(modelData.security)
                              + (Wifi.isSaved(modelData.ssid) ? " · saved" : "")
                              + ` · ${modelData.signal}%`
                    clickable: true
                    enabledRow: !Wifi.busy
                    onClicked: {
                        if (Wifi.isSaved(modelData.ssid)) {
                            Wifi.connectSaved(modelData.ssid)
                        } else if (Wifi.securityLabel(modelData.security) === "Open") {
                            Wifi.connect(modelData.ssid, "")
                        } else {
                            passwordDialog.ssid = modelData.ssid
                            passwordDialog.open = true
                        }
                    }

                    Row {
                        spacing: Appearance.space.xs
                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Wifi.securityLabel(modelData.security) !== "Open"
                            name: "lock"
                            size: 16
                            color: Colors.on.surfaceVariant
                        }
                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "chevron_right"
                            size: 20
                            color: Colors.on.surfaceVariant
                        }
                    }
                }

                MDivider {
                    width: parent.width
                    visible: index < Wifi.networks.filter(n => !n.inUse).length - 1
                }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Wifi.networks.filter(n => !n.inUse).length === 0
            icon: "radar"
            title: "Nothing in range"
            message: "Hit Scan to look again."
        }
    }

    // ---- saved networks -----------------------------------------------------
    MSection {
        width: parent.width
        visible: Wifi.saved.length > 0
        title: "Saved networks"
        icon: "bookmark"
        description: "Networks with a stored password. Forgetting one deletes its "
                   + "NetworkManager connection."

        Repeater {
            model: Wifi.saved

            delegate: Column {
                required property string modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: "wifi_lock"
                    title: modelData
                    subtitle: Wifi.current && Wifi.current.ssid === modelData
                              ? "In use" : "Saved"

                    MButton {
                        icon: "delete"
                        iconSize: 18
                        fg: Colors.error
                        enabled: !Wifi.busy
                        onClicked: Wifi.forget(modelData)
                    }
                }

                MDivider { width: parent.width; visible: index < Wifi.saved.length - 1 }
            }
        }
    }

    MDialog {
        id: passwordDialog
        property string ssid: ""

        title: `Connect to ${ssid}`
        message: "This network is protected."
        icon: "wifi_lock"
        confirmText: "Connect"
        confirmEnabled: pwField.text.length >= 8 || pwField.text.length === 0

        MTextField {
            id: pwField
            width: parent.width
            label: "Password"
            password: !showPw.selected
            errorText: pwField.text.length > 0 && pwField.text.length < 8
                       ? "WPA passwords are at least 8 characters" : ""
            onAccepted: if (passwordDialog.confirmEnabled) passwordDialog.confirmed()
        }

        MChip {
            id: showPw
            label: "Show password"
            icon: "visibility"
            selected: false
            onClicked: selected = !selected
        }

        onConfirmed: {
            Wifi.connect(passwordDialog.ssid, pwField.text)
            pwField.text = ""
        }
        onCancelled: pwField.text = ""
    }

    // nmcli's own error text is the most useful thing we can show on a failure.
    Connections {
        target: Wifi
        function onFailed(message) {
            passwordDialog.open = false
        }
    }
}

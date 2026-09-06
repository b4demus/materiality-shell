import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import "root:/config"
import "root:/components"
import "root:/services"

// Android-style quick settings: toggle tiles, sliders, quick links.
// Toggled by Mod+A, the status island, or `ipc call controlCenter toggle`.
PanelWindow {
    id: root
    visible: Bus.controlCenterOpen
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-controlcenter"
    WlrLayershell.keyboardFocus: Bus.controlCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }


    Process { id: sessionProc }

    Item {
        anchors.fill: parent
        focus: Bus.controlCenterOpen
        Keys.onEscapePressed: Bus.controlCenterOpen = false

        // scrim
        MouseArea {
            anchors.fill: parent
            onClicked: Bus.controlCenterOpen = false
        }
        Rectangle {
            anchors.fill: parent
            color: Colors.scrim
            opacity: root.visible ? 0.35 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }
        }

        // panel
        Rectangle {
            id: panel
            width: 420
            anchors.right: parent.right
            anchors.rightMargin: Appearance.barInsetRight
            anchors.top: parent.top
            anchors.topMargin: root.visible ? Appearance.barInsetTop : -height
            height: Math.min(parent.height - 80, col.implicitHeight + Appearance.space.xl * 2)
            radius: Appearance.radius.xl
            color: Colors.surfaceContainer
            clip: true

            opacity: root.visible ? 1 : 0
            Behavior on anchors.topMargin {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            MouseArea { anchors.fill: parent } // swallow clicks

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.space.xl
                spacing: Appearance.space.l

                Item {
                    width: parent.width
                    height: 36

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Quick settings"
                        color: Colors.on.surface
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.titleLarge
                        font.weight: Appearance.font.weightMedium
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.space.xs

                        function run(cmd) {
                            Bus.controlCenterOpen = false
                            sessionProc.command = cmd
                            sessionProc.running = true
                        }

                        MButton {
                            icon: "settings"
                            iconSize: 17
                            bg: Colors.surfaceContainerHighest
                            fg: Colors.on.surfaceVariant
                            onClicked: {
                                Bus.controlCenterOpen = false
                                Bus.openSettings("")
                            }
                        }
                        MButton {
                            icon: "lock"
                            iconSize: 17
                            bg: Colors.surfaceContainerHighest
                            fg: Colors.on.surfaceVariant
                            onClicked: {
                                Bus.controlCenterOpen = false
                                Bus.locked = true
                            }
                        }
                        MButton {
                            icon: "logout"
                            iconSize: 17
                            bg: Colors.surfaceContainerHighest
                            fg: Colors.on.surfaceVariant
                            onClicked: parent.run(["niri", "msg", "action", "quit", "-s"])
                        }
                        MButton {
                            icon: "restart_alt"
                            iconSize: 17
                            bg: Colors.surfaceContainerHighest
                            fg: Colors.on.surfaceVariant
                            onClicked: parent.run(["systemctl", "reboot"])
                        }
                        MButton {
                            icon: "power_settings_new"
                            iconSize: 17
                            bg: Colors.surfaceContainerHighest
                            fg: Colors.error
                            onClicked: parent.run(["systemctl", "poweroff"])
                        }
                    }
                }

                // ---- toggle tiles (2 columns) --------------------------
                // Which tiles appear, and their order, comes from the settings
                // store (Quick settings section), so this grid is data-driven.
                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: Appearance.space.m
                    rowSpacing: Appearance.space.m
                    readonly property real tileW: (width - columnSpacing) / 2

                    Repeater {
                        model: Settings.val("quickSettings.tiles", [])

                        delegate: QSTile {
                            required property string modelData
                            width: parent.tileW
                            visible: spec.show
                            icon: spec.icon
                            label: spec.label
                            sub: spec.sub
                            active: spec.active
                            enabledTile: spec.enabled
                            onClicked: spec.act()
                            onLongClicked: if (spec.page) Bus.openSettings(spec.page)

                            // One description per tile id, so the delegate itself
                            // stays a plain QSTile.
                            readonly property var spec: {
                                switch (modelData) {
                                case "wifi": return {
                                    show: true, icon: Net.icon, label: "Wi-Fi",
                                    sub: Net.kind === "wifi" ? Net.label : (Net.online ? "Ethernet" : "Off"),
                                    active: Net.online, enabled: Net.hasWifiDevice || Net.online,
                                    page: "wifi", act: () => Net.toggleWifi() }
                                case "bluetooth": return {
                                    show: true, icon: Bt.icon, label: "Bluetooth",
                                    sub: Bt.hasConnection ? Bt.firstName : (Bt.enabled ? "On" : "Off"),
                                    active: Bt.enabled, enabled: Bt.available,
                                    page: "bluetooth", act: () => Bt.toggle() }
                                case "nightlight": return {
                                    show: true, icon: "nightlight", label: "Night light",
                                    sub: NightLight.available ? NightLight.label() : "Not installed",
                                    active: Settings.val("nightLight.enabled", false),
                                    enabled: NightLight.available,
                                    page: "nightlight", act: () => NightLight.toggle() }
                                case "dnd": return {
                                    show: true,
                                    icon: Settings.val("notifications.dnd", false)
                                          ? "do_not_disturb_on" : "notifications",
                                    label: "Do not disturb",
                                    sub: Settings.val("notifications.dnd", false) ? "On" : "Off",
                                    active: Settings.val("notifications.dnd", false), enabled: true,
                                    page: "notifications",
                                    act: () => Settings.toggle("notifications.dnd") }
                                case "mute": return {
                                    show: true, icon: Audio.icon, label: "Mute",
                                    sub: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%",
                                    active: Audio.muted, enabled: Audio.ready,
                                    page: "audio", act: () => Audio.toggleMute() }
                                case "theme": return {
                                    show: true, icon: Colors.dark ? "dark_mode" : "light_mode",
                                    label: Colors.dark ? "Dark" : "Light", sub: "Theme",
                                    active: Colors.dark, enabled: true,
                                    page: "appearance", act: () => Colors.toggleMode() }
                                case "powerprofile": return {
                                    show: Power.hasBattery,
                                    icon: "speed", label: "Power", sub: Power.profileLabel(),
                                    active: Power.profile !== PowerProfile.Balanced, enabled: true,
                                    page: "power",
                                    act: () => Power.setProfile(
                                        Power.profile === PowerProfile.PowerSaver
                                        ? PowerProfile.Balanced : PowerProfile.PowerSaver) }
                                case "vpn": return {
                                    show: false, icon: "vpn_lock", label: "VPN", sub: "",
                                    active: false, enabled: false, page: "wifi", act: () => {} }
                                }
                                return { show: false, icon: "", label: "", sub: "",
                                         active: false, enabled: false, page: "", act: () => {} }
                            }
                        }
                    }
                }

                // ---- night light warmth --------------------------------
                Row {
                    width: parent.width
                    spacing: Appearance.space.m
                    visible: NightLight.available && Settings.val("nightLight.enabled", false)

                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "nightlight"
                        size: 20
                        color: Colors.on.surfaceVariant
                    }
                    MSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 20 - Appearance.space.m
                        activeColor: NightLight.kelvinToColor(
                            Settings.val("nightLight.temperature", 4000))
                        value: 1 - (Settings.val("nightLight.temperature", 4000) - 1700) / 4800
                        onMoved: v => Settings.set("nightLight.temperature",
                                                   Math.round(6500 - v * 4800))
                    }
                }

                // ---- volume slider -----------------------------------
                Row {
                    width: parent.width
                    spacing: Appearance.space.m
                    visible: Settings.val("quickSettings.showVolume", true)
                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: Audio.muted ? "volume_off" : "volume_up"
                        size: 20
                        color: Colors.on.surfaceVariant
                    }
                    MSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 20 - Appearance.space.m
                        value: Audio.muted ? 0 : Audio.volume
                        onMoved: v => Audio.setVolume(v)
                    }
                }

                // ---- brightness slider (only with a backlight) ------
                Row {
                    width: parent.width
                    spacing: Appearance.space.m
                    visible: Brightness.available
                             && Settings.val("quickSettings.showBrightness", true)
                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "brightness_6"
                        size: 20
                        color: Colors.on.surfaceVariant
                    }
                    MSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 20 - Appearance.space.m
                        activeColor: Colors.tertiary
                        value: Brightness.value
                        onMoved: v => Brightness.setValue(v)
                    }
                }

                // ---- notification history ----------------------------
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                Column {
                    width: parent.width
                    spacing: Appearance.space.s

                    Item {
                        width: parent.width
                        height: 28

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Notifications"
                            color: Colors.on.surfaceVariant
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelLarge
                            font.weight: Appearance.font.weightMedium
                        }
                        MButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Notifs.history.length > 0
                            label: "Clear all"
                            fg: Colors.primary
                            minSize: 28
                            onClicked: Notifs.clear()
                        }
                    }

                    Text {
                        width: parent.width
                        visible: Notifs.history.length === 0
                        text: "Nothing here yet"
                        color: Colors.on.surfaceVariant
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.bodySmall
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: Appearance.space.s
                        bottomPadding: Appearance.space.s
                    }

                    MScroll {
                        width: parent.width
                        visible: Notifs.history.length > 0
                        height: Math.min(300, contentHeight)
                        contentHeight: histCol.implicitHeight

                        Column {
                            id: histCol
                            width: parent.width
                            spacing: Appearance.space.xs

                            Repeater {
                                model: Notifs.history

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    width: histCol.width
                                    height: entry.implicitHeight + Appearance.space.m * 2
                                    radius: Appearance.radius.m
                                    color: Colors.surfaceContainerHigh

                                    Column {
                                        id: entry
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Appearance.space.m
                                        anchors.rightMargin: Appearance.space.m
                                        spacing: 2

                                        Item {
                                            width: parent.width
                                            height: appT.implicitHeight

                                            Text {
                                                id: appT
                                                anchors.left: parent.left
                                                width: parent.width - agoT.implicitWidth - Appearance.space.s
                                                text: modelData.appName || "Notification"
                                                elide: Text.ElideRight
                                                color: Colors.primary
                                                font.family: Appearance.fontFamily
                                                font.pixelSize: Appearance.font.labelSmall
                                                font.weight: Appearance.font.weightMedium
                                            }
                                            Text {
                                                id: agoT
                                                anchors.right: parent.right
                                                anchors.verticalCenter: appT.verticalCenter
                                                text: Notifs.ago(modelData.time)
                                                color: Colors.on.surfaceVariant
                                                font.family: Appearance.fontFamily
                                                font.pixelSize: Appearance.font.labelSmall
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            visible: !!modelData.summary
                                            text: modelData.summary
                                            elide: Text.ElideRight
                                            color: Colors.on.surface
                                            font.family: Appearance.fontFamily
                                            font.pixelSize: Appearance.font.bodyMedium
                                            font.weight: Appearance.font.weightMedium
                                        }
                                        Text {
                                            width: parent.width
                                            visible: !!modelData.body
                                            text: modelData.body
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WordWrap
                                            color: Colors.on.surfaceVariant
                                            font.family: Appearance.fontFamily
                                            font.pixelSize: Appearance.font.bodySmall
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

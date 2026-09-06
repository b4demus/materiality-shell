import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Bar"
    subtitle: "Shape and contents of the top bar. Everything here "
              + "is live — the real bar moves as you change it."
    maxWidth: 940

    // Every module the bar can host, with the label shown in the layout editor.
    readonly property var catalog: [
        { id: "workspaces",   label: "Workspaces",    icon: "grid_view" },
        { id: "windowTitle",  label: "Window title",  icon: "title" },
        { id: "clock",        label: "Clock",         icon: "schedule" },
        { id: "date",         label: "Date",          icon: "calendar_month" },
        { id: "media",        label: "Media",         icon: "music_note" },
        { id: "clipboard",    label: "Clipboard",     icon: "content_paste" },
        { id: "kaomoji",      label: "Kaomoji",       icon: "sentiment_satisfied" },
        { id: "tray",         label: "System tray",   icon: "widgets" },
        { id: "statusIsland", label: "Status island", icon: "toggle_on" },
        { id: "wifi",         label: "Wi-Fi",         icon: "wifi" },
        { id: "bluetooth",    label: "Bluetooth",     icon: "bluetooth" },
        { id: "volume",       label: "Volume",        icon: "volume_up" },
        { id: "microphone",   label: "Microphone",    icon: "mic" },
        { id: "battery",      label: "Battery",       icon: "battery_5_bar" },
        { id: "cpu",          label: "CPU",           icon: "memory" },
        { id: "ram",          label: "Memory",        icon: "memory_alt" },
        { id: "sysmon",       label: "System monitor", icon: "monitoring" },
        { id: "temperature",  label: "Temperature",   icon: "device_thermostat" },
        { id: "network",      label: "Network speed", icon: "speed" },
        { id: "vpn",          label: "VPN",           icon: "vpn_lock" },
        { id: "notifications", label: "Notifications", icon: "notifications" },
        { id: "power",        label: "Power",         icon: "power_settings_new" }
    ]

    readonly property var zones: [
        { key: "left",   label: page.vertical ? "Top" : "Left" },
        { key: "center", label: page.vertical ? "Middle" : "Centre" },
        { key: "right",  label: page.vertical ? "Bottom" : "Right" }
    ]
    readonly property bool vertical: Settings.val("bar.position", "top") === "left"
                                     || Settings.val("bar.position", "top") === "right"

    function moduleInfo(id) {
        for (const m of catalog) if (m.id === id) return m
        return { id: id, label: id, icon: "circle" }
    }

    function used() {
        let all = []
        for (const z of zones) all = all.concat(Settings.val("bar.modules." + z.key, []))
        return all
    }

    function moveWithin(zone, index, delta) {
        const list = Settings.val("bar.modules." + zone, []).slice()
        const to = index + delta
        if (to < 0 || to >= list.length) return
        const tmp = list[index]
        list[index] = list[to]
        list[to] = tmp
        Settings.set("bar.modules." + zone, list)
    }

    function removeFrom(zone, index) {
        const list = Settings.val("bar.modules." + zone, []).slice()
        list.splice(index, 1)
        Settings.set("bar.modules." + zone, list)
    }

    function moveToZone(fromZone, index, toZone) {
        const from = Settings.val("bar.modules." + fromZone, []).slice()
        const id = from[index]
        from.splice(index, 1)
        const to = Settings.val("bar.modules." + toZone, []).slice()
        to.push(id)
        Settings.patch({
            ["bar.modules." + fromZone]: from,
            ["bar.modules." + toZone]: to
        })
    }

    function addTo(zone, id) {
        const list = Settings.val("bar.modules." + zone, []).slice()
        if (list.indexOf(id) >= 0) return
        list.push(id)
        Settings.set("bar.modules." + zone, list)
    }

    // Tiles the quick-settings panel knows how to render.
    readonly property var qsCatalog: [
        { id: "wifi",         label: "Wi-Fi",          icon: "wifi" },
        { id: "bluetooth",    label: "Bluetooth",      icon: "bluetooth" },
        { id: "nightlight",   label: "Night light",    icon: "nightlight" },
        { id: "dnd",          label: "Do not disturb", icon: "do_not_disturb_on" },
        { id: "mute",         label: "Mute",           icon: "volume_off" },
        { id: "theme",        label: "Light / dark",   icon: "dark_mode" },
        { id: "powerprofile", label: "Power profile",  icon: "speed" },
        { id: "vpn",          label: "VPN",            icon: "vpn_lock" }
    ]

    function qsInfo(id) {
        for (const t of qsCatalog) if (t.id === id) return t
        return { id: id, label: id, icon: "circle" }
    }

    function moveTile(index, delta) {
        const list = Settings.val("quickSettings.tiles", []).slice()
        const to = index + delta
        if (to < 0 || to >= list.length) return
        const tmp = list[index]
        list[index] = list[to]
        list[to] = tmp
        Settings.set("quickSettings.tiles", list)
    }

    headerActions: [
        MButton {
            icon: "restart_alt"
            label: "Reset"
            bg: Colors.surfaceContainerHigh
            fg: Colors.on.surfaceVariant
            hpad: Appearance.space.l
            onClicked: Settings.reset("bar")
        }
    ]

    // ---- placement ----------------------------------------------------------
    MSection {
        width: parent.width
        title: "Placement"
        icon: "open_with"

        MRow {
            width: parent.width
            icon: "flip_to_front"
            title: "Floating"
            subtitle: Settings.val("bar.floating", true)
                      ? "Detached from the edge with rounded corners"
                      : "Flush against the edge, square corners"

            MSwitch {
                checked: Settings.val("bar.floating", true)
                onToggled: c => Settings.set("bar.floating", c)
            }
        }
    }

    // ---- shape --------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Size & shape"
        icon: "straighten"

        MSliderRow {
            width: parent.width
            icon: "height"
            title: page.vertical ? "Width" : "Height"
            from: 20; to: 72; stepSize: 1; suffix: " px"
            value: Settings.val("bar.height", 32)
            onMoved: v => Settings.set("bar.height", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "space_bar"
            title: "Margin"
            subtitle: "Gap between the bar and the screen edge"
            from: 0; to: 32; stepSize: 1; suffix: " px"
            enabledRow: Settings.val("bar.floating", true)
            value: Settings.val("bar.margin", 6)
            onMoved: v => Settings.set("bar.margin", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "rounded_corner"
            title: "Corner radius"
            from: 0; to: 36; stepSize: 1; suffix: " px"
            enabledRow: Settings.val("bar.floating", true)
            value: Settings.val("bar.radius", 16)
            onMoved: v => Settings.set("bar.radius", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "padding"
            title: "Inner padding"
            from: 0; to: 32; stepSize: 1; suffix: " px"
            value: Settings.val("bar.padding", 14)
            onMoved: v => Settings.set("bar.padding", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "opacity"
            title: "Transparency"
            from: 0; to: 0.8; stepSize: 0.05
            valueText: Math.round(Settings.val("bar.transparency", 0) * 100) + "%"
            value: Settings.val("bar.transparency", 0)
            onMoved: v => Settings.set("bar.transparency", v)
        }
    }

    // ---- contents -----------------------------------------------------------
    MSection {
        width: parent.width
        title: "Contents"
        icon: "view_agenda"
        description: "Arrange modules across the three groups. Use the arrows to reorder, "
                   + "the group icon to move a module elsewhere."

        Repeater {
            model: page.zones

            delegate: Column {
                id: zoneCol
                required property var modelData
                width: parent.width
                spacing: Appearance.space.s

                Text {
                    text: modelData.label
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelLarge
                    font.weight: Appearance.font.weightMedium
                }

                Rectangle {
                    width: parent.width
                    implicitHeight: Math.max(52, zoneFlow.implicitHeight + Appearance.space.m * 2)
                    radius: Appearance.radius.m
                    color: Colors.surfaceContainerHighest

                    Flow {
                        id: zoneFlow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Appearance.space.m
                        spacing: Appearance.space.s

                        Repeater {
                            model: Settings.val("bar.modules." + modelData.key, [])

                            delegate: Rectangle {
                                id: pill
                                required property string modelData
                                required property int index
                                readonly property var info: page.moduleInfo(pill.modelData)
                                readonly property string zoneKey: zoneCol.modelData.key

                                height: 34
                                width: pillRow.implicitWidth + Appearance.space.m * 2
                                radius: Appearance.radius.s
                                color: Colors.secondaryContainer

                                Row {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: Appearance.space.xs

                                    MIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: pill.info.icon
                                        size: 16
                                        color: Colors.on.secondaryContainer
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: pill.info.label
                                        color: Colors.on.secondaryContainer
                                        font.family: Appearance.fontFamily
                                        font.pixelSize: Appearance.font.labelMedium
                                        font.weight: Appearance.font.weightMedium
                                        rightPadding: Appearance.space.xs
                                    }

                                    MIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: page.vertical ? "keyboard_arrow_up" : "chevron_left"
                                        size: 16
                                        color: Colors.on.secondaryContainer
                                        opacity: pill.index > 0 ? 0.8 : 0.25
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -3
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: page.moveWithin(pill.zoneKey, pill.index, -1)
                                        }
                                    }
                                    MIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: page.vertical ? "keyboard_arrow_down" : "chevron_right"
                                        size: 16
                                        color: Colors.on.secondaryContainer
                                        opacity: 0.8
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -3
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: page.moveWithin(pill.zoneKey, pill.index, 1)
                                        }
                                    }
                                    MIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "swap_horiz"
                                        size: 16
                                        color: Colors.on.secondaryContainer
                                        opacity: 0.8
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -3
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                // cycle left -> center -> right -> left
                                                const order = ["left", "center", "right"]
                                                const i = order.indexOf(pill.zoneKey)
                                                page.moveToZone(pill.zoneKey, pill.index,
                                                                order[(i + 1) % order.length])
                                            }
                                        }
                                    }
                                    MIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "close"
                                        size: 16
                                        color: Colors.on.secondaryContainer
                                        opacity: 0.8
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -3
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: page.removeFrom(pill.zoneKey, pill.index)
                                        }
                                    }
                                }
                            }
                        }

                        MChip {
                            label: "Add"
                            icon: "add"
                            showCheck: false
                            onClicked: {
                                addModule.zone = zoneCol.modelData.key
                                addModule.open = true
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- module metrics -----------------------------------------------------
    MSection {
        width: parent.width
        title: "Module metrics"
        icon: "tune"

        MSliderRow {
            width: parent.width
            icon: "photo_size_select_small"
            title: "Icon size"
            from: 12; to: 28; stepSize: 1; suffix: " px"
            value: Settings.val("bar.iconSize", 18)
            onMoved: v => Settings.set("bar.iconSize", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "format_size"
            title: "Text size"
            from: 9; to: 20; stepSize: 1; suffix: " px"
            value: Settings.val("bar.fontSize", 13)
            onMoved: v => Settings.set("bar.fontSize", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "space_dashboard"
            title: "Space between modules"
            from: 2; to: 32; stepSize: 1; suffix: " px"
            value: Settings.val("bar.moduleSpacing", 14)
            onMoved: v => Settings.set("bar.moduleSpacing", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "grid_view"
            title: "Space between workspaces"
            from: 0; to: 20; stepSize: 1; suffix: " px"
            value: Settings.val("bar.workspaceSpacing", 6)
            onMoved: v => Settings.set("bar.workspaceSpacing", v)
        }
    }

    // ---- quick settings panel -------------------------------------------------
    MSection {
        width: parent.width
        title: "Quick settings panel"
        icon: "dashboard"
        description: "The panel that drops down from the bar. Tiles appear in the order "
                   + "listed here."

        Flow {
            width: parent.width
            spacing: Appearance.space.s

            Repeater {
                model: page.qsCatalog

                delegate: MChip {
                    required property var modelData
                    readonly property var tiles: Settings.val("quickSettings.tiles", [])
                    label: modelData.label
                    icon: modelData.icon
                    selected: tiles.indexOf(modelData.id) >= 0
                    onClicked: {
                        const next = tiles.slice()
                        const i = next.indexOf(modelData.id)
                        if (i >= 0) next.splice(i, 1)
                        else next.push(modelData.id)
                        Settings.set("quickSettings.tiles", next)
                    }
                }
            }
        }

        MDivider { width: parent.width }

        // Order, with the same arrow controls as the bar zones.
        Flow {
            width: parent.width
            spacing: Appearance.space.s

            Repeater {
                model: Settings.val("quickSettings.tiles", [])

                delegate: Rectangle {
                    id: tilePill
                    required property string modelData
                    required property int index
                    readonly property var info: page.qsInfo(tilePill.modelData)

                    height: 34
                    width: tileRow.implicitWidth + Appearance.space.m * 2
                    radius: Appearance.radius.s
                    color: Colors.surfaceContainerHighest

                    Row {
                        id: tileRow
                        anchors.centerIn: parent
                        spacing: Appearance.space.xs

                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: tilePill.info.icon
                            size: 16
                            color: Colors.on.surfaceVariant
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tilePill.info.label
                            color: Colors.on.surface
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelMedium
                            rightPadding: Appearance.space.xs
                        }
                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "chevron_left"
                            size: 16
                            color: Colors.on.surfaceVariant
                            opacity: tilePill.index > 0 ? 0.8 : 0.25
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -3
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.moveTile(tilePill.index, -1)
                            }
                        }
                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "chevron_right"
                            size: 16
                            color: Colors.on.surfaceVariant
                            opacity: 0.8
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -3
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.moveTile(tilePill.index, 1)
                            }
                        }
                    }
                }
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "volume_up"
            title: "Volume slider"

            MSwitch {
                checked: Settings.val("quickSettings.showVolume", true)
                onToggled: c => Settings.set("quickSettings.showVolume", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "brightness_6"
            title: "Brightness slider"
            subtitle: Brightness.available ? "" : "No backlight device on this machine"
            enabledRow: Brightness.available

            MSwitch {
                checked: Settings.val("quickSettings.showBrightness", true)
                enabledSwitch: Brightness.available
                onToggled: c => Settings.set("quickSettings.showBrightness", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "music_note"
            title: "Media player"

            MSwitch {
                checked: Settings.val("quickSettings.showMedia", true)
                onToggled: c => Settings.set("quickSettings.showMedia", c)
            }
        }
    }

    // ---- add-module dialog ---------------------------------------------------
    MDialog {
        id: addModule
        property string zone: "left"
        title: "Add a module"
        message: "Modules already on the bar are hidden from this list."
        icon: "add_circle"
        cancelText: "Done"
        confirmText: ""
        dialogWidth: 480

        Flow {
            width: parent.width
            spacing: Appearance.space.s

            Repeater {
                model: page.catalog.filter(m => page.used().indexOf(m.id) < 0)
                delegate: MChip {
                    required property var modelData
                    label: modelData.label
                    icon: modelData.icon
                    showCheck: false
                    onClicked: page.addTo(addModule.zone, modelData.id)
                }
            }
        }
    }
}

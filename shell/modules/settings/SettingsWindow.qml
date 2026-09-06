pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/components"
import "root:/services"

// ---------------------------------------------------------------------------
// The settings application: a real desktop window (not a layer-shell panel),
// so it tiles in niri like any other app.
//
// Layout adapts to the window size — expanded navigation, icon rail, or a
// dropdown in the header — and the page area is a single Loader so pages stay
// independent files that know nothing about each other.
// ---------------------------------------------------------------------------
FloatingWindow {
    id: root

    property string page: "appearance"
    property string search: ""

    title: "Materiality Settings"
    minimumSize: Qt.size(560, 420)
    implicitWidth: 1180
    implicitHeight: 820
    color: Colors.background

    // The Bus drives the window open, but the compositor can close it on its own
    // (Mod+Q, a close button) — and doing so *overwrites* this binding with a
    // plain `false`. If we don't notice, `Bus.settingsOpen` stays true forever
    // and the next `openSettings()` is a silent no-op (the window never reopens
    // until the whole shell is restarted). So: when the window disappears while
    // the Bus still thinks it's open, sync the flag back and re-establish the
    // binding.
    visible: Bus.settingsOpen

    onVisibleChanged: {
        if (visible) {
            Displays.refresh()
            NiriConf.refresh()
            Shortcuts.refresh()
            Apps.refreshAutostart()
        } else if (Bus.settingsOpen) {
            Bus.settingsOpen = false
            visible = Qt.binding(() => Bus.settingsOpen)
        }
    }

    // ---- navigation model -------------------------------------------------
    readonly property var nav: [
        { group: "Appearance", items: [
            { id: "appearance",  icon: "palette",            label: "Theme & colour" },
            { id: "wallpaper",   icon: "wallpaper",          label: "Wallpaper" },
            { id: "bar",         icon: "toolbar",            label: "Bar" },
            { id: "motion",      icon: "animation",          label: "Motion & density" }
        ]},
        { group: "Compositor", items: [
            { id: "niri",        icon: "view_column",        label: "Niri" },
            { id: "windows",     icon: "select_window",      label: "Windows" },
            { id: "workspaces",  icon: "grid_view",          label: "Workspaces" }
        ]},
        { group: "Devices", items: [
            { id: "displays",    icon: "desktop_windows",    label: "Displays" },
            { id: "nightlight",  icon: "nightlight",         label: "Night light" },
            { id: "wifi",        icon: "wifi",               label: "Wi-Fi" },
            { id: "bluetooth",   icon: "bluetooth",          label: "Bluetooth" },
            { id: "audio",       icon: "volume_up",          label: "Sound" },
            { id: "keyboard",    icon: "keyboard",           label: "Keyboard" },
            { id: "pointer",     icon: "mouse",              label: "Mouse & touchpad" }
        ]},
        { group: "Behaviour", items: [
            { id: "shortcuts",   icon: "keyboard_command_key", label: "Shortcuts" },
            { id: "notifications", icon: "notifications",    label: "Notifications" },
            { id: "privacy",     icon: "shield",             label: "Privacy" },
            { id: "power",       icon: "battery_charging_full", label: "Power" },
            { id: "applications", icon: "apps",              label: "Applications" }
        ]},
        { group: "System", items: [
            { id: "profiles",    icon: "tune",               label: "Profiles" },
            { id: "automation",  icon: "auto_awesome",       label: "Automation" },
            { id: "autostart",   icon: "rocket_launch",      label: "Startup apps" },
            { id: "about",       icon: "info",               label: "About" }
        ]}
    ]

    readonly property var flatNav: {
        const out = []
        for (const g of nav) for (const i of g.items) out.push(i)
        return out
    }

    function navItem(id) {
        for (const i of flatNav) if (i.id === id) return i
        return flatNav[0]
    }

    // Search filters destinations by label; empty search shows the groups.
    readonly property var searchResults: {
        const q = search.trim().toLowerCase()
        if (!q) return []
        return flatNav.filter(i => i.label.toLowerCase().indexOf(q) >= 0
                                   || i.id.indexOf(q) >= 0)
    }

    // ---- responsive breakpoints -------------------------------------------
    readonly property bool wide: width >= 1080
    readonly property bool medium: width >= 780 && !wide
    readonly property bool compact: width < 780
    readonly property real navWidth: wide ? 248 : (medium ? 72 : 0)

    function go(id) {
        if (id === root.page) return
        root.page = id
        root.search = ""
        pageAnim.restart()
    }

    // Shared toast so any page can confirm an action.
    property alias toast: toastItem

    // Deep links from elsewhere in the shell (bar, quick settings, IPC).
    Connections {
        target: Bus
        function onSettingsPageChanged() {
            if (Bus.settingsPage) {
                root.go(Bus.settingsPage)
                Bus.settingsPage = ""
            }
        }
    }

    Item {
        id: shellRootItem
        anchors.fill: parent

        // ---- navigation -----------------------------------------------------
        Rectangle {
            id: navPane
            width: root.navWidth
            height: parent.height
            color: Colors.surfaceContainerLow
            visible: !root.compact
            clip: true

            Behavior on width { NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }

            Column {
                anchors.fill: parent
                anchors.margins: Appearance.space.s
                anchors.topMargin: Appearance.space.l
                spacing: Appearance.space.s

                // brand
                Item {
                    width: parent.width
                    height: 44

                    Rectangle {
                        id: mark
                        x: root.wide ? Appearance.space.m : (parent.width - width) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32; height: 32
                        radius: Appearance.radius.s
                        color: Colors.primaryContainer
                        MIcon {
                            anchors.centerIn: parent
                            name: "settings"
                            size: 19
                            fill: 1
                            color: Colors.on.primaryContainer
                        }
                        Behavior on x { NumberAnimation { duration: Motion.durMedium } }
                    }
                    Text {
                        anchors.left: mark.right
                        anchors.leftMargin: Appearance.space.m
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.wide
                        text: "Settings"
                        color: Colors.on.surface
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.titleMedium
                        font.weight: Appearance.font.weightMedium
                    }
                }

                // search (expanded nav only)
                Rectangle {
                    visible: root.wide
                    width: parent.width - Appearance.space.s * 2
                    x: Appearance.space.s
                    height: 40
                    radius: Appearance.radius.full
                    color: Colors.surfaceContainerHighest

                    MIcon {
                        id: searchIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.space.m
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        size: 18
                        color: Colors.on.surfaceVariant
                    }
                    TextInput {
                        id: searchInput
                        anchors.left: searchIcon.right
                        anchors.leftMargin: Appearance.space.s
                        anchors.right: parent.right
                        anchors.rightMargin: Appearance.space.m
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.search
                        color: Colors.on.surface
                        selectionColor: Colors.primary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.bodyMedium
                        clip: true
                        selectByMouse: true
                        onTextChanged: root.search = text
                        Keys.onEscapePressed: { text = ""; focus = false }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: "Search settings"
                            color: Colors.on.surfaceVariant
                            font: searchInput.font
                        }
                    }
                }

                // destinations
                MScroll {
                    width: parent.width
                    height: parent.height - y
                    contentHeight: navCol.implicitHeight
                    showBar: false

                    Column {
                        id: navCol
                        width: parent.width
                        spacing: 2

                        // search results replace the grouped list while typing
                        Repeater {
                            model: root.searchResults
                            delegate: MNavItem {
                                required property var modelData
                                width: navCol.width
                                expanded: root.wide
                                icon: modelData.icon
                                label: modelData.label
                                selected: root.page === modelData.id
                                onClicked: root.go(modelData.id)
                            }
                        }

                        Repeater {
                            model: root.search.trim() ? [] : root.nav

                            delegate: Column {
                                required property var modelData
                                width: navCol.width
                                spacing: 2
                                topPadding: Appearance.space.m

                                Text {
                                    visible: root.wide
                                    leftPadding: Appearance.space.l
                                    bottomPadding: Appearance.space.xs
                                    text: modelData.group
                                    color: Colors.on.surfaceVariant
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelSmall
                                    font.weight: Appearance.font.weightMedium
                                }

                                Rectangle {
                                    visible: !root.wide
                                    x: Appearance.space.l
                                    width: parent.width - Appearance.space.l * 2
                                    height: 1
                                    color: Colors.outlineVariant
                                    opacity: 0.5
                                }

                                Repeater {
                                    model: modelData.items
                                    delegate: MNavItem {
                                        required property var modelData
                                        width: navCol.width
                                        expanded: root.wide
                                        icon: modelData.icon
                                        label: modelData.label
                                        selected: root.page === modelData.id
                                        onClicked: root.go(modelData.id)
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: Appearance.space.xl }
                    }
                }
            }
        }

        // ---- content ---------------------------------------------------------
        Item {
            id: contentPane
            anchors.left: navPane.visible ? navPane.right : parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // compact header with a page picker
            Item {
                id: compactBar
                visible: root.compact
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: visible ? 64 : 0

                MSelect {
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.space.l
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.space.l
                    anchors.verticalCenter: parent.verticalCenter
                    model: root.flatNav.map(i => ({ value: i.id, label: i.label, icon: i.icon }))
                    value: root.page
                    onPicked: v => root.go(v)
                }
            }

            Loader {
                id: pageLoader
                anchors.top: compactBar.visible ? compactBar.bottom : parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                asynchronous: false
                source: `pages/${root.pageFile(root.page)}`

                opacity: 0
                Component.onCompleted: opacity = 1
            }

            // Expressive page entry: fade + a short rise.
            SequentialAnimation {
                id: pageAnim
                PropertyAction { target: pageLoader; property: "opacity"; value: 0 }
                PropertyAction { target: pageLoader; property: "y"; value: 14 }
                ParallelAnimation {
                    NumberAnimation {
                        target: pageLoader; property: "opacity"; to: 1
                        duration: Motion.durMedium; easing.type: Motion.easeStandard
                    }
                    NumberAnimation {
                        target: pageLoader; property: "y"; to: 0
                        duration: Motion.durLong; easing.type: Motion.easeDecel
                    }
                }
            }
        }

        MToast { id: toastItem }
    }

    // Page ids map to files; keeping it explicit avoids loading a path built
    // from anything but this table.
    function pageFile(id) {
        const map = {
            "appearance": "AppearancePage.qml",
            "wallpaper": "WallpaperPage.qml",
            "bar": "BarPage.qml",
            "motion": "MotionPage.qml",
            "niri": "NiriPage.qml",
            "windows": "WindowsPage.qml",
            "workspaces": "WorkspacesPage.qml",
            "displays": "DisplaysPage.qml",
            "nightlight": "NightLightPage.qml",
            "wifi": "WifiPage.qml",
            "bluetooth": "BluetoothPage.qml",
            "audio": "AudioPage.qml",
            "keyboard": "KeyboardPage.qml",
            "pointer": "PointerPage.qml",
            "shortcuts": "ShortcutsPage.qml",
            "notifications": "NotificationsPage.qml",
            "privacy": "PrivacyPage.qml",
            "power": "PowerPage.qml",
            "applications": "ApplicationsPage.qml",
            "profiles": "ProfilesPage.qml",
            "automation": "AutomationPage.qml",
            "autostart": "AutostartPage.qml",
            "about": "AboutPage.qml"
        }
        return map[id] || map["appearance"]
    }
}

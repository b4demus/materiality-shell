import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Applications"
    subtitle: "Which program opens what. These are the system-wide XDG defaults, so "
              + "every application respects them, not just this shell."
    maxWidth: 880

    property string pickingRole: ""

    MSection {
        width: parent.width
        title: "Default applications"
        icon: "open_in_new"

        Repeater {
            model: Apps.roles

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: modelData.icon
                    title: modelData.label
                    subtitle: Apps.nameFor(Apps.defaults[modelData.key] || "")
                    clickable: true
                    onClicked: {
                        page.pickingRole = modelData.key
                        appPicker.roleLabel = modelData.label
                        appPicker.open = true
                    }

                    MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
                }
            }
        }
    }

    MSection {
        width: parent.width
        title: "Shell helpers"
        icon: "terminal"
        description: "Programs the shell launches itself — from a keybind, or when you "
                   + "click something in the bar."

        MRow {
            width: parent.width
            icon: "terminal"
            title: "Terminal"
            subtitle: "Used by the terminal keybind"

            MTextField {
                width: 220
                text: Settings.val("apps.terminal", "alacritty")
                onEdited: t => Settings.set("apps.terminal", t)
            }
        }
    }

    MSection {
        width: parent.width
        title: "Related"
        icon: "link"

        MRow {
            width: parent.width
            icon: "rocket_launch"
            title: "Startup applications"
            subtitle: `${Apps.autostart.filter(a => a.enabled).length} enabled`
            clickable: true
            onClicked: Bus.settingsPage = "autostart"

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }
    }

    // ---- picker ---------------------------------------------------------------
    MDialog {
        id: appPicker
        property string roleLabel: ""

        title: `Choose a ${roleLabel.toLowerCase()}`
        icon: "apps"
        cancelText: "Cancel"
        confirmText: ""
        dialogWidth: 520

        MTextField {
            id: appSearch
            width: parent.width
            label: "Search applications"
            leadingIcon: "search"
        }

        MScroll {
            width: parent.width
            height: 320
            contentHeight: appCol.implicitHeight

            Column {
                id: appCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: {
                        const q = appSearch.text.trim().toLowerCase()
                        const pool = Apps.visibleApps
                        return (q ? pool.filter(a => String(a.name).toLowerCase().indexOf(q) >= 0)
                                  : pool).slice(0, 80)
                    }
                    delegate: MRow {
                        required property var modelData
                        width: appCol.width
                        minHeight: 48
                        icon: "web_asset"
                        title: modelData.name
                        subtitle: modelData.genericName || modelData.id
                        clickable: true
                        onClicked: {
                            Apps.setDefault(page.pickingRole, modelData.id)
                            appPicker.open = false
                        }
                    }
                }
            }
        }
    }
}

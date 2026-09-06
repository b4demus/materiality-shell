import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Startup applications"
    subtitle: "Programs launched when your session begins. These are ordinary "
              + "~/.config/autostart entries, which niri runs through xdg-desktop-autostart."
    maxWidth: 860

    headerActions: [
        MButton {
            icon: "terminal"
            label: "Add command"
            bg: Colors.surfaceContainerHigh
            fg: Colors.on.surfaceVariant
            hpad: Appearance.space.l
            onClicked: cmdDialog.open = true
        },
        MButton {
            icon: "add"
            label: "Add app"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            onClicked: appDialog.open = true
        }
    ]

    MSection {
        width: parent.width
        title: ""

        Repeater {
            model: Apps.autostart

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: modelData.enabled ? "play_circle" : "pause_circle"
                    title: modelData.name
                    subtitle: modelData.exec

                    Row {
                        spacing: Appearance.space.s

                        MSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: modelData.enabled
                            onToggled: c => Apps.setAutostartEnabled(modelData.file, c)
                        }
                        MButton {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "delete"
                            iconSize: 18
                            fg: Colors.error
                            onClicked: {
                                removeDialog.entry = modelData
                                removeDialog.open = true
                            }
                        }
                    }
                }

                MDivider { width: parent.width; visible: index < Apps.autostart.length - 1 }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Apps.autostart.length === 0
            icon: "rocket_launch"
            title: "Nothing starts automatically"
            message: "Add an application, or a plain command line, to run it at login."
        }
    }

    MSection {
        width: parent.width
        title: "Started by niri itself"
        icon: "settings_applications"
        description: "The shell is launched from your niri config with "
                   + "spawn-at-startup, not from here."

        MRow {
            width: parent.width
            icon: "widgets"
            title: "Materiality shell"
            subtitle: "qs -c expressive"
        }
    }

    MDialog {
        id: appDialog
        title: "Add a startup application"
        icon: "apps"
        cancelText: "Cancel"
        confirmText: ""
        dialogWidth: 520

        MTextField {
            id: startSearch
            width: parent.width
            label: "Search applications"
            leadingIcon: "search"
        }

        MScroll {
            width: parent.width
            height: 300
            contentHeight: startCol.implicitHeight

            Column {
                id: startCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: {
                        const q = startSearch.text.trim().toLowerCase()
                        const pool = Apps.visibleApps
                        return (q ? pool.filter(a => String(a.name).toLowerCase().indexOf(q) >= 0)
                                  : pool).slice(0, 80)
                    }
                    delegate: MRow {
                        required property var modelData
                        width: startCol.width
                        minHeight: 48
                        icon: "web_asset"
                        title: modelData.name
                        subtitle: modelData.genericName || modelData.id
                        clickable: true
                        onClicked: {
                            Apps.addAutostart(modelData.id)
                            appDialog.open = false
                        }
                    }
                }
            }
        }
    }

    MDialog {
        id: cmdDialog
        title: "Run a command at startup"
        message: "Anything you would type in a terminal."
        icon: "terminal"
        confirmText: "Add"
        confirmEnabled: cmdName.text.trim().length > 0 && cmdExec.text.trim().length > 0

        MTextField {
            id: cmdName
            width: parent.width
            label: "Name"
        }
        MTextField {
            id: cmdExec
            width: parent.width
            label: "Command"
            placeholder: "syncthing --no-browser"
        }

        onConfirmed: {
            Apps.addAutostartCommand(cmdName.text.trim(), cmdExec.text.trim())
            cmdName.text = ""
            cmdExec.text = ""
        }
    }

    MDialog {
        id: removeDialog
        property var entry: null

        title: "Remove from startup?"
        message: entry ? `${entry.name} will no longer start with your session. `
                       + "The application itself is not uninstalled." : ""
        icon: "delete"
        destructive: true
        confirmText: "Remove"
        onConfirmed: if (entry) Apps.removeAutostart(entry.file)
    }
}

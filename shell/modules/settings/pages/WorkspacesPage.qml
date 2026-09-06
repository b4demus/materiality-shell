import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Workspaces"
    subtitle: "niri creates and destroys workspaces on demand, so these settings "
              + "decorate them rather than fix their number."
    maxWidth: 900

    readonly property var named: Settings.val("workspaces.named", [])

    readonly property var iconChoices: [
        "circle", "code", "terminal", "public", "chat", "mail", "folder", "music_note",
        "movie", "sports_esports", "brush", "science", "school", "work", "photo_camera"
    ]
    readonly property var colorChoices: [
        "", "#e57373", "#f0a05a", "#e5c07b", "#98c379", "#56b6c2",
        "#61afef", "#8d7ce0", "#c678dd", "#9aa0a6"
    ]

    function entryFor(idx) {
        for (const e of named) if (e.idx === idx) return e
        return null
    }

    function setEntry(idx, changes) {
        const next = named.slice()
        let found = false
        for (let i = 0; i < next.length; i++) {
            if (next[i].idx === idx) {
                next[i] = Object.assign({}, next[i], changes)
                found = true
            }
        }
        if (!found) next.push(Object.assign({ idx: idx, name: "", icon: "", color: "" }, changes))
        Settings.set("workspaces.named", next)
    }

    // ---- indicator ---------------------------------------------------------
    MSection {
        width: parent.width
        title: "Indicator"
        icon: "grid_view"
        description: "How workspaces are drawn in the bar."

        MRow {
            width: parent.width
            icon: "style"
            title: "Style"

            MSegmented {
                width: 280
                model: [
                    { value: "pill",    label: "Pills",   icon: "pill" },
                    { value: "dots",    label: "Dots",    icon: "more_horiz" },
                    { value: "numbers", label: "Numbers", icon: "123" }
                ]
                value: Settings.val("workspaces.indicatorStyle", "pill")
                onPicked: v => Settings.set("workspaces.indicatorStyle", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "label"
            title: "Show names in the bar"
            subtitle: "Otherwise only the active workspace is labelled"

            MSwitch {
                checked: Settings.val("workspaces.showLabels", false)
                onToggled: c => Settings.set("workspaces.showLabels", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "emoji_symbols"
            title: "Show icons"

            MSwitch {
                checked: Settings.val("workspaces.showIcons", true)
                onToggled: c => Settings.set("workspaces.showIcons", c)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "space_dashboard"
            title: "Spacing"
            from: 0; to: 20; stepSize: 1; suffix: " px"
            value: Settings.val("bar.workspaceSpacing", 6)
            onMoved: v => Settings.set("bar.workspaceSpacing", v)
        }
    }

    // ---- live workspaces ----------------------------------------------------
    MSection {
        width: parent.width
        title: "Your workspaces"
        icon: "dashboard"
        description: "Names, icons and colours are remembered per index, so they stick "
                   + "even as niri adds and removes workspaces."

        Repeater {
            model: Niri.workspaces.slice().sort((a, b) => a.idx - b.idx)

            delegate: Rectangle {
                id: wsCard
                required property var modelData
                readonly property var entry: page.entryFor(modelData.idx)

                width: parent.width
                implicitHeight: wsCol.implicitHeight + Appearance.space.l * 2
                radius: Appearance.radius.m
                color: modelData.is_focused ? Colors.secondaryContainer : Colors.surfaceContainerHighest

                Behavior on color { ColorAnimation { duration: Motion.durMedium } }

                Column {
                    id: wsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.space.l
                    spacing: Appearance.space.m

                    Row {
                        width: parent.width
                        spacing: Appearance.space.m

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36; height: 36
                            radius: Appearance.radius.s
                            color: (wsCard.entry && wsCard.entry.color)
                                   ? wsCard.entry.color : Colors.primary

                            MIcon {
                                anchors.centerIn: parent
                                visible: wsCard.entry && wsCard.entry.icon
                                name: (wsCard.entry && wsCard.entry.icon) || "circle"
                                size: 18
                                color: Colors.on.primary
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !(wsCard.entry && wsCard.entry.icon)
                                text: wsCard.modelData.idx
                                color: Colors.on.primary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.titleMedium
                                font.weight: Appearance.font.weightMedium
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 36 - 90 - Appearance.space.m * 2
                            spacing: 2

                            Text {
                                text: (wsCard.entry && wsCard.entry.name)
                                      || wsCard.modelData.name
                                      || `Workspace ${wsCard.modelData.idx}`
                                color: Colors.on.surface
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.bodyLarge
                                font.weight: Appearance.font.weightMedium
                            }
                            Text {
                                text: `${wsCard.modelData.output || "—"}`
                                      + (wsCard.modelData.is_focused ? " · focused"
                                         : wsCard.modelData.is_active ? " · active" : "")
                                color: Colors.on.surfaceVariant
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.bodySmall
                            }
                        }

                        MButton {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "arrow_forward"
                            label: "Go"
                            iconSize: 16
                            bg: Colors.surfaceContainer
                            fg: Colors.on.surfaceVariant
                            onClicked: Niri.focusWorkspace(wsCard.modelData.idx)
                        }
                    }

                    MTextField {
                        width: parent.width
                        label: "Name"
                        text: (wsCard.entry && wsCard.entry.name) || ""
                        onEdited: t => page.setEntry(wsCard.modelData.idx, { name: t })
                    }

                    Flow {
                        width: parent.width
                        spacing: Appearance.space.xs

                        Repeater {
                            model: page.iconChoices
                            delegate: MChip {
                                required property string modelData
                                icon: modelData
                                hpad: Appearance.space.s
                                selected: wsCard.entry && wsCard.entry.icon === modelData
                                onClicked: page.setEntry(wsCard.modelData.idx, {
                                    icon: (wsCard.entry && wsCard.entry.icon === modelData)
                                          ? "" : modelData
                                })
                            }
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: Appearance.space.xs

                        Repeater {
                            model: page.colorChoices
                            delegate: MSwatch {
                                required property string modelData
                                size_: 30
                                swatch: modelData === "" ? Colors.primary : modelData
                                selected: wsCard.entry
                                          ? (wsCard.entry.color || "") === modelData
                                          : modelData === ""
                                onClicked: page.setEntry(wsCard.modelData.idx, { color: modelData })
                            }
                        }
                    }
                }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Niri.workspaces.length === 0
            icon: "grid_view"
            title: Niri.connected ? "No workspaces yet" : "Not connected to niri"
            message: Niri.connected
                     ? "Open a window and niri will create one."
                     : "The workspace list comes from niri's event stream."
        }
    }
}

import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Profiles"
    subtitle: "A profile is a saved set of settings you can switch to in one move — "
              + "for gaming, presenting, or working on battery."
    maxWidth: 900

    property string editingId: ""
    readonly property var editing: editingId ? Profiles.byId(editingId) : null

    headerActions: [
        MButton {
            icon: "add"
            label: "New profile"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            onClicked: {
                const id = Profiles.create("New profile", "tune")
                page.editingId = id
                Profiles.captureCurrent(id)
            }
        }
    ]

    // ---- the profiles -------------------------------------------------------
    MSection {
        width: parent.width
        title: "Your profiles"
        icon: "tune"

        Repeater {
            model: Profiles.list

            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property bool active: Profiles.activeId === modelData.id
                readonly property bool expanded: page.editingId === modelData.id

                width: parent.width
                implicitHeight: cardCol.implicitHeight + Appearance.space.l * 2
                radius: Appearance.radius.l
                color: active ? Colors.secondaryContainer : Colors.surfaceContainerHighest

                Behavior on color { ColorAnimation { duration: Motion.durMedium } }

                Column {
                    id: cardCol
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
                            width: 44; height: 44
                            radius: Appearance.radius.s
                            color: card.active ? Colors.primary : Colors.surfaceContainer

                            MIcon {
                                anchors.centerIn: parent
                                name: card.modelData.icon || "tune"
                                size: 22
                                fill: card.active ? 1 : 0
                                color: card.active ? Colors.on.primary : Colors.on.surfaceVariant
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 44 - 200 - Appearance.space.m * 2
                            spacing: 2

                            Text {
                                text: card.modelData.name
                                color: Colors.on.surface
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.titleMedium
                                font.weight: Appearance.font.weightMedium
                            }
                            Text {
                                text: card.active
                                      ? "Active"
                                      : `${Object.keys(card.modelData.patch || {}).length} settings`
                                color: Colors.on.surfaceVariant
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.bodySmall
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Appearance.space.xs

                            MButton {
                                label: card.active ? "Active" : "Apply"
                                icon: card.active ? "check" : "play_arrow"
                                iconSize: 16
                                bg: card.active ? Colors.primary : Colors.surfaceContainer
                                fg: card.active ? Colors.on.primary : Colors.on.surfaceVariant
                                hpad: Appearance.space.m
                                onClicked: card.active ? Profiles.clearActive()
                                                       : Profiles.apply(card.modelData.id)
                            }
                            MButton {
                                icon: card.expanded ? "expand_less" : "edit"
                                iconSize: 18
                                fg: Colors.on.surfaceVariant
                                onClicked: page.editingId = card.expanded ? "" : card.modelData.id
                            }
                        }
                    }

                    // ---- editor ---------------------------------------------
                    Column {
                        width: parent.width
                        visible: card.expanded
                        spacing: Appearance.space.m

                        MDivider { width: parent.width }

                        MTextField {
                            width: parent.width
                            label: "Name"
                            text: card.modelData.name
                            onEdited: t => Profiles.update(card.modelData.id, { name: t })
                        }

                        Flow {
                            width: parent.width
                            spacing: Appearance.space.xs

                            Repeater {
                                model: Profiles.icons
                                delegate: MChip {
                                    required property string modelData
                                    icon: modelData
                                    hpad: Appearance.space.s
                                    selected: card.modelData.icon === modelData
                                    onClicked: Profiles.update(card.modelData.id, { icon: modelData })
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: Appearance.space.s

                            MButton {
                                icon: "photo_camera"
                                label: "Capture current settings"
                                bg: Colors.surfaceContainer
                                fg: Colors.on.surfaceVariant
                                hpad: Appearance.space.l
                                onClicked: Profiles.captureCurrent(card.modelData.id)
                            }
                            MButton {
                                icon: "delete"
                                label: "Delete"
                                fg: Colors.error
                                hpad: Appearance.space.l
                                onClicked: {
                                    deleteDialog.target = card.modelData
                                    deleteDialog.open = true
                                }
                            }
                        }

                        Text {
                            text: "What this profile changes"
                            color: Colors.on.surfaceVariant
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelLarge
                            font.weight: Appearance.font.weightMedium
                        }

                        // Each supported setting, with a chip controlling whether the
                        // profile carries it at all, and a control for its value.
                        Repeater {
                            model: Profiles.fields

                            delegate: Item {
                                id: fieldRow
                                required property var modelData

                                readonly property var patch: card.modelData.patch || ({})
                                readonly property bool included: patch[modelData.path] !== undefined
                                readonly property var current: patch[modelData.path]

                                function write(v) {
                                    const p = Object.assign({}, fieldRow.patch)
                                    p[fieldRow.modelData.path] = v
                                    Profiles.update(card.modelData.id, { patch: p })
                                }
                                function toggleIncluded() {
                                    const p = Object.assign({}, fieldRow.patch)
                                    if (fieldRow.included) delete p[fieldRow.modelData.path]
                                    else p[fieldRow.modelData.path] =
                                        Settings.val(fieldRow.modelData.path, null)
                                    Profiles.update(card.modelData.id, { patch: p })
                                }

                                width: parent.width
                                implicitHeight: 48

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 300
                                    elide: Text.ElideRight
                                    text: fieldRow.modelData.label
                                    color: fieldRow.included ? Colors.on.surface
                                                             : Colors.on.surfaceVariant
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.bodyMedium
                                }

                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Appearance.space.m

                                    MSwitch {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: fieldRow.included
                                                 && fieldRow.modelData.kind === "bool"
                                        checked: fieldRow.current === true
                                        onToggled: c => fieldRow.write(c)
                                    }

                                    MSelect {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: fieldRow.included
                                                 && fieldRow.modelData.kind === "choice"
                                        width: 150
                                        model: (fieldRow.modelData.choices || [])
                                               .map(c => ({ value: c, label: c }))
                                        value: fieldRow.current
                                        onPicked: v => fieldRow.write(v)
                                    }

                                    MStepper {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: fieldRow.included
                                                 && fieldRow.modelData.kind === "int"
                                        value: Number(fieldRow.current) || 0
                                        from: fieldRow.modelData.min !== undefined
                                              ? fieldRow.modelData.min : 0
                                        to: fieldRow.modelData.max !== undefined
                                            ? fieldRow.modelData.max : 100
                                        stepSize: 1
                                        onChanged: v => fieldRow.write(v)
                                    }

                                    MChip {
                                        anchors.verticalCenter: parent.verticalCenter
                                        label: fieldRow.included ? "Included" : "Ignored"
                                        selected: fieldRow.included
                                        hpad: Appearance.space.m
                                        onClicked: fieldRow.toggleIncluded()
                                    }
                                }
                            }
                        }

                        MTextField {
                            width: parent.width
                            label: "Command to run when applied (optional)"
                            text: (card.modelData.commands || []).join("; ")
                            onEdited: t => Profiles.update(card.modelData.id,
                                { commands: t.trim() ? [t.trim()] : [] })
                        }
                    }
                }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Profiles.list.length === 0
            icon: "tune"
            title: "No profiles yet"
            message: "Set the desktop up the way you like it, then create a profile — "
                   + "it captures the current values so you can come back to them."
        }
    }

    MSection {
        width: parent.width
        title: "Related"
        icon: "link"

        MRow {
            width: parent.width
            icon: "auto_awesome"
            title: "Automation"
            subtitle: Profiles.automationOn
                      ? `${Profiles.rules.filter(r => r.enabled).length} active rules`
                      : "Off — profiles only switch when you ask"
            clickable: true
            onClicked: Bus.settingsPage = "automation"

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }
    }

    MDialog {
        id: deleteDialog
        property var target: null

        title: "Delete this profile?"
        message: target ? `“${target.name}” will be removed. Settings it applied stay as they are.` : ""
        icon: "delete"
        destructive: true
        confirmText: "Delete"
        onConfirmed: if (target) {
            if (page.editingId === target.id) page.editingId = ""
            Profiles.remove(target.id)
        }
    }
}

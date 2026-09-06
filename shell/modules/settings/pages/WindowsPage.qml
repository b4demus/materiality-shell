import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Windows"
    subtitle: "How new windows are sized and placed, plus per-application rules."
    maxWidth: 940

    readonly property var rules: Settings.val("windows.rules", [])

    function updateRule(index, changes) {
        const next = rules.slice()
        next[index] = Object.assign({}, next[index], changes)
        Settings.set("windows.rules", next)
    }
    function removeRule(index) {
        const next = rules.slice()
        next.splice(index, 1)
        Settings.set("windows.rules", next)
    }

    // ---- a diagram of what the numbers mean --------------------------------
    MSection {
        width: parent.width
        title: "Layout"
        icon: "view_column"
        description: "niri lays windows out as a horizontal strip of columns. The default "
                   + "column width decides how much room a fresh window claims."

        Item {
            width: parent.width
            height: 150

            Rectangle {
                anchors.fill: parent
                radius: Appearance.radius.m
                color: Colors.surfaceContainerHighest
                clip: true

                readonly property real g: Settings.val("niri.gapsInner", 8) * 0.6
                readonly property real w: Settings.val("niri.defaultColumnWidth", 0.5)
                readonly property real r: Settings.val("niri.cornerRadius", 14) * 0.5

                Row {
                    anchors.fill: parent
                    anchors.margins: parent.g + 10
                    spacing: parent.g

                    Rectangle {
                        width: (parent.width - parent.spacing) * parent.parent.w
                        height: parent.height
                        radius: parent.parent.r
                        color: Colors.primaryContainer
                        border.width: Settings.val("niri.focusRingEnabled", true)
                                      ? Math.max(1, Settings.val("niri.focusRingWidth", 3) * 0.6) : 0
                        border.color: Colors.primary

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(parent.parent.parent.w * 100) + "%"
                            color: Colors.on.primaryContainer
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.titleMedium
                            font.weight: Appearance.font.weightMedium
                        }
                    }
                    Rectangle {
                        width: parent.width - (parent.width - parent.spacing)
                               * parent.parent.w - parent.spacing
                        height: parent.height
                        radius: parent.parent.r
                        color: Colors.surfaceContainerLow
                    }
                }
            }
        }

        MSliderRow {
            width: parent.width
            icon: "width_wide"
            title: "Default column width"
            from: 0.2; to: 1.0; stepSize: 0.05
            valueText: Math.round(Settings.val("niri.defaultColumnWidth", 0.5) * 100) + "%"
            value: Settings.val("niri.defaultColumnWidth", 0.5)
            onMoved: v => Settings.set("niri.defaultColumnWidth", v)
        }
    }

    // ---- floating windows ----------------------------------------------------
    MSection {
        width: parent.width
        title: "Floating windows"
        icon: "flip_to_front"
        description: "Size used when a window opens floating, or is toggled out of the "
                   + "tiling strip."

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "crop"
            title: "Clip windows to their rounded corners"
            subtitle: "Stops square window content bleeding past the corner radius"

            MSwitch {
                checked: Settings.val("windows.clipToGeometry", true)
                onToggled: c => Settings.set("windows.clipToGeometry", c)
            }
        }
    }

    // ---- per-app rules -------------------------------------------------------
    MSection {
        width: parent.width
        title: "Application rules"
        icon: "rule"
        description: "Rules are matched on the window's app id and title, and written to "
                   + "niri as window-rule blocks."

        Repeater {
            model: page.rules

            delegate: Rectangle {
                id: ruleCard
                required property var modelData
                required property int index

                width: parent.width
                implicitHeight: ruleCol.implicitHeight + Appearance.space.l * 2
                radius: Appearance.radius.m
                color: Colors.surfaceContainerHighest

                Column {
                    id: ruleCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.space.l
                    spacing: Appearance.space.m

                    Row {
                        width: parent.width
                        spacing: Appearance.space.m

                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "web_asset"
                            size: 20
                            color: Colors.primary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 20 - 32 - Appearance.space.m * 2
                            text: ruleCard.modelData.appId || ruleCard.modelData.title || "Any window"
                            elide: Text.ElideRight
                            color: Colors.on.surface
                            font.family: Appearance.monoFamily
                            font.pixelSize: Appearance.font.bodyMedium
                        }
                        MButton {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "delete"
                            iconSize: 18
                            fg: Colors.error
                            onClicked: page.removeRule(ruleCard.index)
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: Appearance.space.s

                        MChip {
                            label: "Floating"
                            icon: "flip_to_front"
                            selected: ruleCard.modelData.floating === true
                            onClicked: page.updateRule(ruleCard.index,
                                                       { floating: !ruleCard.modelData.floating })
                        }
                        MChip {
                            label: "Maximised"
                            icon: "crop_free"
                            selected: ruleCard.modelData.maximized === true
                            onClicked: page.updateRule(ruleCard.index,
                                                       { maximized: !ruleCard.modelData.maximized })
                        }
                        MChip {
                            label: "Fullscreen"
                            icon: "fullscreen"
                            selected: ruleCard.modelData.fullscreen === true
                            onClicked: page.updateRule(ruleCard.index,
                                                       { fullscreen: !ruleCard.modelData.fullscreen })
                        }
                        MChip {
                            label: "Hide from screen capture"
                            icon: "visibility_off"
                            selected: ruleCard.modelData.blockOut === true
                            onClicked: page.updateRule(ruleCard.index,
                                                       { blockOut: !ruleCard.modelData.blockOut })
                        }
                    }
                }
            }
        }

        MEmptyState {
            width: parent.width
            visible: page.rules.length === 0
            icon: "rule"
            title: "No application rules"
            message: "Add one to make a particular app open floating, maximised, or hidden "
                   + "from screen capture."
        }

        MButton {
            icon: "add"
            label: "Add rule"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            onClicked: {
                newRule.appId = ""
                newRule.titleMatch = ""
                newRule.open = true
            }
        }
    }

    MDialog {
        id: newRule
        property string appId: ""
        property string titleMatch: ""

        title: "New window rule"
        message: "Both fields are regular expressions. Leave the title empty to match "
               + "every window of the app."
        icon: "rule"
        confirmText: "Add"
        confirmEnabled: appIdField.text.trim().length > 0 || titleField.text.trim().length > 0
        dialogWidth: 480

        Column {
            width: parent.width
            spacing: Appearance.space.m

            MTextField {
                id: appIdField
                width: parent.width
                label: "App id"
                placeholder: "firefox$"
            }
            MTextField {
                id: titleField
                width: parent.width
                label: "Title (optional)"
                placeholder: "^Picture-in-Picture$"
            }

            // The open windows are the most likely thing you want to match.
            Text {
                visible: openWindows.model.length > 0
                text: "Currently open"
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelMedium
            }
            Flow {
                width: parent.width
                spacing: Appearance.space.s

                Repeater {
                    id: openWindows
                    model: {
                        const seen = {}
                        const out = []
                        for (const id in Niri._windows) {
                            const w = Niri._windows[id]
                            if (w && w.app_id && !seen[w.app_id]) {
                                seen[w.app_id] = true
                                out.push(w.app_id)
                            }
                        }
                        return out
                    }
                    delegate: MChip {
                        required property string modelData
                        label: modelData
                        icon: "web_asset"
                        showCheck: false
                        onClicked: appIdField.text = "^" + modelData.replace(/\./g, "\\.") + "$"
                    }
                }
            }
        }

        onConfirmed: {
            const next = page.rules.slice()
            next.push({
                appId: appIdField.text.trim(),
                title: titleField.text.trim(),
                floating: false, maximized: false, fullscreen: false, blockOut: false
            })
            Settings.set("windows.rules", next)
            appIdField.text = ""
            titleField.text = ""
        }
    }
}

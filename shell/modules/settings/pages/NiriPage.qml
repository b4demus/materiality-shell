import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Niri"
    subtitle: "The compositor's own layout rules. These are written into "
              + "~/.config/niri/config.kdl, which niri reloads as it is saved."
    maxWidth: 940

    headerActions: [
        MButton {
            icon: "science"
            label: "Validate"
            bg: Colors.surfaceContainerHigh
            fg: Colors.on.surfaceVariant
            hpad: Appearance.space.l
            onClicked: NiriConf.refresh()
        }
    ]

    // A visible, honest error surface: if niri rejects a generated config we
    // keep the old file and say so rather than failing silently.
    MCard {
        width: parent.width
        visible: NiriConf.lastError !== ""
        tone: Colors.errorContainer

        Row {
            width: parent.width
            spacing: Appearance.space.m

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "error"
                size: 22
                color: Colors.on.errorContainer
            }
            Column {
                width: parent.width - 22 - Appearance.space.m
                spacing: 2
                Text {
                    text: "niri rejected the last change — your config was left untouched"
                    color: Colors.on.errorContainer
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodyMedium
                    font.weight: Appearance.font.weightMedium
                }
                Text {
                    width: parent.width
                    text: NiriConf.lastError
                    wrapMode: Text.WordWrap
                    color: Colors.on.errorContainer
                    font.family: Appearance.monoFamily
                    font.pixelSize: Appearance.font.labelSmall
                }
            }
        }
    }

    // ---- gaps ---------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Gaps"
        icon: "space_bar"

        MSliderRow {
            width: parent.width
            icon: "width_normal"
            title: "Gaps between windows"
            from: 0; to: 48; stepSize: 1; suffix: " px"
            value: Settings.val("niri.gapsInner", 8)
            onMoved: v => Settings.set("niri.gapsInner", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "crop_free"
            title: "Gaps at the screen edge"
            subtitle: "Written as niri struts, on top of the bar's own reserved space"
            from: 0; to: 96; stepSize: 2; suffix: " px"
            value: Settings.val("niri.gapsOuter", 0)
            onMoved: v => Settings.set("niri.gapsOuter", v)
        }
    }

    // ---- window decoration --------------------------------------------------
    MSection {
        width: parent.width
        title: "Window decoration"
        icon: "rounded_corner"

        MSliderRow {
            width: parent.width
            icon: "rounded_corner"
            title: "Window corner radius"
            subtitle: "Applied to every window through a managed window rule"
            from: 0; to: 32; stepSize: 1; suffix: " px"
            value: Settings.val("niri.cornerRadius", 14)
            onMoved: v => Settings.set("niri.cornerRadius", v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "highlight_alt"
            title: "Focus ring"
            subtitle: "Drawn around the focused window; recoloured by the palette"

            MSwitch {
                checked: Settings.val("niri.focusRingEnabled", true)
                onToggled: c => Settings.set("niri.focusRingEnabled", c)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "line_weight"
            title: "Focus ring width"
            from: 1; to: 12; stepSize: 1; suffix: " px"
            enabledRow: Settings.val("niri.focusRingEnabled", true)
            value: Settings.val("niri.focusRingWidth", 3)
            onMoved: v => Settings.set("niri.focusRingWidth", v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "border_style"
            title: "Border"
            subtitle: "Always-visible outline. Usually you want either this or the "
                    + "focus ring, not both."

            MSwitch {
                checked: Settings.val("niri.borderEnabled", false)
                onToggled: c => Settings.set("niri.borderEnabled", c)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "line_weight"
            title: "Border width"
            from: 1; to: 12; stepSize: 1; suffix: " px"
            enabledRow: Settings.val("niri.borderEnabled", false)
            value: Settings.val("niri.borderWidth", 2)
            onMoved: v => Settings.set("niri.borderWidth", v)
        }
    }

    // ---- focus --------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Focus & columns"
        icon: "center_focus_strong"

        MRow {
            width: parent.width
            icon: "my_location"
            title: "Centre the focused column"

            MSelect {
                width: 220
                model: [
                    { value: "never",       label: "Never",       hint: "Columns stay where they are" },
                    { value: "on-overflow", label: "On overflow", hint: "Centre only when it won't fit" },
                    { value: "always",      label: "Always",      hint: "Focused column is always centred" }
                ]
                value: Settings.val("niri.centerFocusedColumn", "never")
                onPicked: v => Settings.set("niri.centerFocusedColumn", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "ads_click"
            title: "Focus follows mouse"
            subtitle: "Moving the pointer onto a window focuses it"

            MSwitch {
                checked: Settings.val("niri.focusFollowsMouse", false)
                onToggled: c => Settings.set("niri.focusFollowsMouse", c)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "width_wide"
            title: "Default column width"
            subtitle: "Share of the screen a new window takes"
            from: 0.2; to: 1.0; stepSize: 0.05
            valueText: Math.round(Settings.val("niri.defaultColumnWidth", 0.5) * 100) + "%"
            value: Settings.val("niri.defaultColumnWidth", 0.5)
            onMoved: v => Settings.set("niri.defaultColumnWidth", v)
        }

        MDivider { width: parent.width }

        // preset widths — the sizes Mod+R cycles through
        Column {
            width: parent.width
            spacing: Appearance.space.m

            Text {
                text: "Preset column widths"
                color: Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyLarge
                font.weight: Appearance.font.weightMedium
            }
            Text {
                width: parent.width
                text: "The widths the “switch preset column width” key cycles through."
                wrapMode: Text.WordWrap
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodySmall
            }

            Flow {
                width: parent.width
                spacing: Appearance.space.s

                Repeater {
                    model: [0.25, 0.33333, 0.4, 0.5, 0.6, 0.66667, 0.75, 1.0]
                    delegate: MChip {
                        required property real modelData
                        readonly property var presets: Settings.val("niri.presetColumnWidths", [])
                        label: Math.round(modelData * 100) + "%"
                        selected: presets.some(p => Math.abs(p - modelData) < 0.005)
                        onClicked: {
                            const next = presets.filter(p => Math.abs(p - modelData) >= 0.005)
                            if (next.length === presets.length) next.push(modelData)
                            next.sort((a, b) => a - b)
                            // niri needs at least one preset to cycle through.
                            Settings.set("niri.presetColumnWidths",
                                         next.length > 0 ? next : [0.5])
                        }
                    }
                }
            }
        }
    }

    // ---- actions -------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Session"
        icon: "restart_alt"

        MRow {
            width: parent.width
            icon: "refresh"
            title: "Reload the shell"
            subtitle: "Restarts Quickshell without touching your niri session"
            clickable: true
            onClicked: Quickshell.reload(true)

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "backup"
            title: "Config backup"
            subtitle: "Every write keeps the previous config.kdl at "
                    + "~/.local/state/expressive/niri-config.kdl.bak"
        }
    }
}

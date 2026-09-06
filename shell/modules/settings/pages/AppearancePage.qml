import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Theme & colour"
    subtitle: "How the whole desktop looks — every change lands on the real "
              + "shell as you make it."

    // ---- theme mode -------------------------------------------------------
    MSection {
        width: parent.width
        title: "Theme"
        icon: "contrast"

        MRow {
            width: parent.width
            icon: "brightness_medium"
            title: "Appearance"
            subtitle: Colors.mode === "system"
                      ? `Following the desktop preference (currently ${Colors.systemPref})`
                      : "Applies to the shell, GTK apps and the terminal"

            MSegmented {
                width: 260
                model: [
                    { value: "light",  label: "Light",  icon: "light_mode" },
                    { value: "dark",   label: "Dark",   icon: "dark_mode" },
                    { value: "system", label: "Auto",   icon: "brightness_auto" }
                ]
                value: Colors.mode
                onPicked: v => Colors.setMode(v)
            }
        }
    }

    // ---- colour source ----------------------------------------------------
    MSection {
        width: parent.width
        title: "Colour"
        icon: "palette"
        description: "Material You builds the whole palette from one seed colour. "
                   + "That seed is either taken from your wallpaper or picked by hand."

        MRow {
            width: parent.width
            icon: "auto_awesome"
            title: "Colours from wallpaper"
            subtitle: Settings.val("appearance.dynamicColors", true)
                      ? "The palette regenerates whenever the wallpaper changes"
                      : "Using the accent colour chosen below"

            MSwitch {
                checked: Settings.val("appearance.dynamicColors", true)
                onToggled: c => Settings.set("appearance.dynamicColors", c)
            }
        }

        MDivider { width: parent.width }

        // accent picker — only meaningful with dynamic colour off
        Column {
            width: parent.width
            spacing: Appearance.space.m
            opacity: Settings.val("appearance.dynamicColors", true) ? 0.45 : 1
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            Text {
                text: "Accent colour"
                color: Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyLarge
                font.weight: Appearance.font.weightMedium
            }

            Flow {
                width: parent.width
                spacing: Appearance.space.s

                Repeater {
                    model: Theme.accentSwatches
                    delegate: MSwatch {
                        required property string modelData
                        swatch: modelData
                        selected: Settings.val("appearance.accent", "").toLowerCase()
                                  === modelData.toLowerCase()
                        enabled: !Settings.val("appearance.dynamicColors", true)
                        onClicked: if (!Settings.val("appearance.dynamicColors", true))
                                       Theme.setAccent(modelData)
                    }
                }

                // pick any colour from the screen with niri's colour picker
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.outline

                    MIcon {
                        anchors.centerIn: parent
                        name: "colorize"
                        size: 18
                        color: Colors.on.surfaceVariant
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !Settings.val("appearance.dynamicColors", true)
                        onClicked: pickColor.running = true
                    }
                }
            }
        }

        MDivider { width: parent.width }

        // curated schemes
        Column {
            width: parent.width
            spacing: Appearance.space.m

            Text {
                text: "Palette"
                color: Colors.on.surface
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyLarge
                font.weight: Appearance.font.weightMedium
            }
            Text {
                width: parent.width
                text: "Dynamic follows the wallpaper. Auto picks whichever curated scheme "
                    + "is closest to it. The rest are fixed palettes."
                wrapMode: Text.WordWrap
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodySmall
            }

            Flow {
                width: parent.width
                spacing: Appearance.space.s

                Repeater {
                    model: Theme.schemes
                    delegate: MChip {
                        required property var modelData
                        label: modelData.label
                        selected: Theme.current === modelData.name
                        enabledChip: !Theme.busy
                        onClicked: Theme.setScheme(modelData.name)
                    }
                }
            }
        }
    }

    // ---- shape & surfaces --------------------------------------------------
    MSection {
        width: parent.width
        title: "Shape & surfaces"
        icon: "rounded_corner"

        MSliderRow {
            width: parent.width
            icon: "rounded_corner"
            title: "Corner radius"
            subtitle: "Scales every rounded corner in the shell at once"
            from: 0.4
            to: 1.6
            stepSize: 0.05
            decimals: 2
            suffix: "×"
            value: Settings.val("appearance.radiusScale", 1.0)
            onMoved: v => Settings.set("appearance.radiusScale", v)
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "opacity"
            title: "Transparency"
            subtitle: "Applies to the bar and floating panels"
            from: 0
            to: 0.6
            stepSize: 0.02
            decimals: 0
            valueText: Math.round(Settings.val("appearance.transparency", 0) * 100) + "%"
            value: Settings.val("appearance.transparency", 0)
            onMoved: v => Settings.set("appearance.transparency", v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "layers"
            title: "Shadows"
            subtitle: "Soft drop shadows under floating surfaces"

            MSwitch {
                checked: Settings.val("appearance.shadows", true)
                onToggled: c => Settings.set("appearance.shadows", c)
            }
        }
    }

    // ---- typography --------------------------------------------------------
    MSection {
        width: parent.width
        title: "Type"
        icon: "text_fields"

        MRow {
            width: parent.width
            icon: "font_download"
            title: "Interface font"
            subtitle: "Used across the shell and this window"

            MSelect {
                width: 240
                model: fontList.families.map(f => ({ value: f, label: f }))
                value: Settings.val("appearance.fontFamily", "Roboto")
                onPicked: v => Settings.set("appearance.fontFamily", v)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "format_size"
            title: "Text size"
            from: 0.85
            to: 1.3
            stepSize: 0.05
            decimals: 0
            valueText: Math.round(Settings.val("appearance.fontScale", 1) * 100) + "%"
            value: Settings.val("appearance.fontScale", 1.0)
            onMoved: v => Settings.set("appearance.fontScale", v)
        }
    }

    // ---- cursor & icons ----------------------------------------------------
    MSection {
        width: parent.width
        title: "Cursor & icons"
        icon: "mouse"
        description: "Cursor changes reach newly launched apps; already-running ones "
                   + "keep the old theme until they restart."

        MRow {
            width: parent.width
            icon: "navigation"
            title: "Cursor theme"

            MSelect {
                width: 240
                model: themeList.cursors.map(c => ({ value: c, label: c }))
                value: Settings.val("appearance.cursorTheme", "Adwaita")
                onPicked: v => {
                    Settings.set("appearance.cursorTheme", v)
                    applyCursor.exec(v, Settings.val("appearance.cursorSize", 24))
                }
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "photo_size_select_small"
            title: "Cursor size"

            MStepper {
                value: Settings.val("appearance.cursorSize", 24)
                from: 16
                to: 64
                stepSize: 4
                suffix: " px"
                onChanged: v => {
                    Settings.set("appearance.cursorSize", v)
                    applyCursor.exec(Settings.val("appearance.cursorTheme", "Adwaita"), v)
                }
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "apps"
            title: "Icon theme"
            subtitle: "Used by GTK applications"

            MSelect {
                width: 240
                model: themeList.icons.map(c => ({ value: c, label: c }))
                value: Settings.val("appearance.iconTheme", "Adwaita")
                onPicked: v => {
                    Settings.set("appearance.iconTheme", v)
                    applyIcons.command = ["gsettings", "set", "org.gnome.desktop.interface",
                                          "icon-theme", v]
                    applyIcons.running = true
                }
            }
        }
    }

    // ---- helpers ------------------------------------------------------------
    QtObject {
        id: fontList
        // Deliberately a short, curated list: enumerating every installed face
        // makes this menu useless.
        readonly property var families: ["Roboto", "Inter", "Cantarell", "Noto Sans",
                                         "DejaVu Sans", "JetBrains Mono", "Roboto Mono"]
    }

    Item {
        id: themeList
        property var cursors: ["Adwaita"]
        property var icons: ["Adwaita"]

        Process {
            running: true
            command: ["sh", "-c",
                'ls -1 /usr/share/icons ~/.icons ~/.local/share/icons 2>/dev/null | sort -u | ' +
                'while read -r d; do [ -n "$d" ] || continue; ' +
                'for base in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do ' +
                '  if [ -d "$base/$d/cursors" ]; then echo "C\\t$d"; break; fi; done; ' +
                'for base in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do ' +
                '  if [ -f "$base/$d/index.theme" ] && [ ! -d "$base/$d/cursors" ]; then echo "I\\t$d"; break; fi; done; ' +
                'done']
            stdout: StdioCollector {
                onStreamFinished: {
                    const c = [], i = []
                    for (const line of text.trim().split("\n")) {
                        const p = line.split("\t")
                        if (p.length < 2) continue
                        if (p[0] === "C") c.push(p[1])
                        else i.push(p[1])
                    }
                    if (c.length > 0) themeList.cursors = c
                    if (i.length > 0) themeList.icons = i
                }
            }
        }
    }

    Process {
        id: applyCursor
        function exec(theme, size) {
            command = ["sh", "-c",
                'gsettings set org.gnome.desktop.interface cursor-theme "$1"; ' +
                'gsettings set org.gnome.desktop.interface cursor-size "$2"',
                "sh", String(theme), String(size)]
            running = true
        }
    }
    Process { id: applyIcons }

    // niri's own colour picker feeds the accent, so you can seed the palette
    // from anything on screen.
    Process {
        id: pickColor
        command: ["niri", "msg", "--json", "pick-color"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text)
                    const rgb = c.rgb || c
                    const hex = "#" + [rgb[0], rgb[1], rgb[2]]
                        .map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("")
                    Theme.setAccent(hex)
                } catch (e) {}
            }
        }
    }
}

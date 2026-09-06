import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Displays"
    subtitle: "Changes apply to the running session immediately. Use “Keep” to write "
              + "them into niri's config so they survive a restart."
    maxWidth: 940

    readonly property var out: Displays.find(Displays.selected)

    headerActions: [
        MButton {
            icon: "refresh"
            label: "Rescan"
            bg: Colors.surfaceContainerHigh
            fg: Colors.on.surfaceVariant
            hpad: Appearance.space.l
            onClicked: Displays.refresh()
        },
        MButton {
            icon: "save"
            label: "Keep"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            onClicked: Displays.persist()
        }
    ]

    // ---- arrangement map ----------------------------------------------------
    MSection {
        width: parent.width
        title: "Arrangement"
        icon: "space_dashboard"
        description: Displays.outputs.length > 1
                     ? "Drag a monitor to move it. Positions are in logical pixels."
                     : "Only one monitor is connected."

        Item {
            width: parent.width
            height: 220

            Rectangle {
                anchors.fill: parent
                radius: Appearance.radius.m
                color: Colors.surfaceContainerHighest
                clip: true

                // Fit every output's bounding box into the map.
                readonly property var bounds: {
                    let minX = 0, minY = 0, maxX = 1, maxY = 1
                    for (const o of Displays.outputs) {
                        const l = o.logical
                        minX = Math.min(minX, l.x)
                        minY = Math.min(minY, l.y)
                        maxX = Math.max(maxX, l.x + l.width)
                        maxY = Math.max(maxY, l.y + l.height)
                    }
                    return { x: minX, y: minY, w: maxX - minX, h: maxY - minY }
                }
                readonly property real k: Math.min((width - 40) / bounds.w,
                                                   (height - 40) / bounds.h)

                Repeater {
                    model: Displays.outputs

                    delegate: Rectangle {
                        id: mon
                        required property var modelData
                        readonly property var map: parent
                        readonly property bool sel: Displays.selected === modelData.name

                        x: map.width / 2 - (map.bounds.w * map.k) / 2
                           + (modelData.logical.x - map.bounds.x) * map.k
                        y: map.height / 2 - (map.bounds.h * map.k) / 2
                           + (modelData.logical.y - map.bounds.y) * map.k
                        width: Math.max(40, modelData.logical.width * map.k)
                        height: Math.max(30, modelData.logical.height * map.k)

                        radius: Appearance.radius.xs
                        color: sel ? Colors.primaryContainer : Colors.surfaceContainerLow
                        border.width: sel ? 2 : 1
                        border.color: sel ? Colors.primary : Colors.outlineVariant

                        Behavior on color { ColorAnimation { duration: Motion.durShort } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: mon.modelData.name
                                color: mon.sel ? Colors.on.primaryContainer : Colors.on.surface
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.labelMedium
                                font.weight: Appearance.font.weightMedium
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: parent.parent.height > 46
                                text: `${mon.modelData.logical.width}×${mon.modelData.logical.height}`
                                color: mon.sel ? Colors.on.primaryContainer : Colors.on.surfaceVariant
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.labelSmall
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Displays.outputs.length > 1 ? Qt.SizeAllCursor
                                                                     : Qt.PointingHandCursor
                            drag.target: Displays.outputs.length > 1 ? mon : null
                            drag.axis: Drag.XAndYAxis
                            onPressed: Displays.selected = mon.modelData.name
                            onReleased: {
                                if (Displays.outputs.length < 2) return
                                // Convert the dropped position back into logical pixels.
                                const nx = Math.round(
                                    (mon.x - (mon.map.width / 2 - (mon.map.bounds.w * mon.map.k) / 2))
                                    / mon.map.k + mon.map.bounds.x)
                                const ny = Math.round(
                                    (mon.y - (mon.map.height / 2 - (mon.map.bounds.h * mon.map.k) / 2))
                                    / mon.map.k + mon.map.bounds.y)
                                Displays.applyPosition(mon.modelData.name, nx, ny)
                            }
                        }
                    }
                }
            }
        }

        Flow {
            width: parent.width
            spacing: Appearance.space.s
            visible: Displays.outputs.length > 1

            Repeater {
                model: Displays.outputs
                delegate: MChip {
                    required property var modelData
                    label: modelData.name
                    icon: "monitor"
                    selected: Displays.selected === modelData.name
                    onClicked: Displays.selected = modelData.name
                }
            }
        }
    }

    // ---- selected monitor ---------------------------------------------------
    MSection {
        width: parent.width
        visible: page.out !== null
        title: page.out ? page.out.name : ""
        icon: "monitor"
        description: page.out
                     ? [page.out.make, page.out.model].filter(s => s && s !== "Unknown").join(" ")
                       || "Generic display"
                     : ""

        MRow {
            width: parent.width
            icon: "aspect_ratio"
            title: "Resolution"

            MSelect {
                width: 240
                model: page.out
                       ? Displays.resolutions(page.out).map(m => ({
                             value: `${m.width}x${m.height}`,
                             label: `${m.width} × ${m.height}`
                         }))
                       : []
                value: page.out && page.out.modes[page.out.currentMode]
                       ? `${page.out.modes[page.out.currentMode].width}x${page.out.modes[page.out.currentMode].height}`
                       : ""
                onPicked: v => {
                    const parts = v.split("x")
                    const rates = Displays.refreshRatesFor(page.out, parseInt(parts[0]),
                                                           parseInt(parts[1]))
                    if (rates.length > 0)
                        Displays.applyMode(page.out.name, Displays.modeString(rates[0]))
                }
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "refresh"
            title: "Refresh rate"

            MSelect {
                width: 240
                model: {
                    if (!page.out) return []
                    const cur = page.out.modes[page.out.currentMode]
                    if (!cur) return []
                    return Displays.refreshRatesFor(page.out, cur.width, cur.height)
                        .map(m => ({ value: Displays.modeString(m),
                                     label: `${(m.refresh_rate / 1000).toFixed(2)} Hz`
                                            + (m.is_preferred ? "  (preferred)" : "") }))
                }
                value: page.out && page.out.modes[page.out.currentMode]
                       ? Displays.modeString(page.out.modes[page.out.currentMode]) : ""
                onPicked: v => Displays.applyMode(page.out.name, v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "zoom_in"
            title: "Scale"
            subtitle: "Fractional scales are supported; 1.5 means 150%"

            MSelect {
                width: 180
                model: [
                    { value: 1.0,  label: "100%" },
                    { value: 1.25, label: "125%" },
                    { value: 1.5,  label: "150%" },
                    { value: 1.75, label: "175%" },
                    { value: 2.0,  label: "200%" },
                    { value: 3.0,  label: "300%" }
                ]
                value: page.out ? page.out.logical.scale : 1.0
                onPicked: v => Displays.applyScale(page.out.name, v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "screen_rotation"
            title: "Orientation"

            MSelect {
                width: 220
                model: Displays.transforms.map(t => ({ value: t.value, label: t.label }))
                value: page.out ? String(page.out.logical.transform).toLowerCase() : "normal"
                onPicked: v => Displays.applyTransform(page.out.name, v)
            }
        }

        MDivider { width: parent.width; visible: page.out && page.out.vrrSupported }

        MRow {
            width: parent.width
            visible: page.out && page.out.vrrSupported
            icon: "monitor_heart"
            title: "Variable refresh rate"
            subtitle: "Matches the refresh rate to what is being drawn"

            MSwitch {
                checked: page.out ? page.out.vrrEnabled : false
                onToggled: c => Displays.applyVrr(page.out.name, c)
            }
        }

        MDivider { width: parent.width; visible: Displays.outputs.length > 1 }

        MRow {
            width: parent.width
            visible: Displays.outputs.length > 1
            icon: "power_settings_new"
            title: "Turn this display off"
            subtitle: "Comes back with Rescan, or by unplugging and replugging"
            clickable: true
            onClicked: Displays.applyEnabled(page.out.name, false)

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }
    }

    MSection {
        width: parent.width
        title: "Related"
        icon: "link"

        MRow {
            width: parent.width
            icon: "nightlight"
            title: "Night light"
            subtitle: NightLight.label()
            clickable: true
            onClicked: Bus.settingsPage = "nightlight"

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "wallpaper"
            title: "Wallpaper for this monitor"
            clickable: true
            onClicked: Bus.settingsPage = "wallpaper"

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }
    }
}

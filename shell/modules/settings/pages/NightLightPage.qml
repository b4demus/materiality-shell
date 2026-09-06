import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Night light"
    subtitle: "Shifts the display towards warmer colours in the evening. This drives "
              + "the real gamma ramps through niri, not an overlay drawn on top."
    maxWidth: 900

    readonly property int temp: Settings.val("nightLight.temperature", 4000)
    readonly property bool on: Settings.val("nightLight.enabled", false)
                               && Settings.val("nightLight.schedule", "manual") !== "off"

    // ---- backend missing ----------------------------------------------------
    MEmptyState {
        width: parent.width
        visible: !NightLight.available
        icon: "extension_off"
        title: "No gamma backend installed"
        message: "Colour temperature needs a wlr-gamma-control client. Install one and "
               + "this page takes over from there — nothing else to configure."
        code: NightLight.installHint
        actionLabel: "Check again"
        onActionClicked: NightLight.refresh()
    }

    // ---- preview ------------------------------------------------------------
    MCard {
        width: parent.width
        visible: NightLight.available
        tone: Colors.surfaceContainerLowest
        padding: Appearance.space.m
        gap: Appearance.space.m

        // Same image, side by side: neutral versus the chosen temperature.
        Item {
            width: parent.width
            height: Math.round(width * 0.26)

            Row {
                anchors.fill: parent
                spacing: Appearance.space.m

                Repeater {
                    model: [false, true]

                    delegate: Rectangle {
                        required property bool modelData
                        width: (parent.width - Appearance.space.m) / 2
                        height: parent.height
                        radius: Appearance.radius.m
                        color: Colors.surfaceContainerHigh
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: Wallpaper.source
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 600
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: parent.modelData
                            color: NightLight.tintFor(page.temp)
                            opacity: 0.5
                            Behavior on color { ColorAnimation { duration: Motion.durMedium } }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: Appearance.space.s
                            width: label.implicitWidth + Appearance.space.m
                            height: 24
                            radius: Appearance.radius.xs
                            color: Qt.rgba(0, 0, 0, 0.55)
                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: parent.parent.modelData ? `${page.temp} K` : "6500 K"
                                color: "#FFFFFF"
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.labelMedium
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- switch + temperature -----------------------------------------------
    MSection {
        width: parent.width
        visible: NightLight.available
        title: "Warmth"
        icon: "nightlight"

        MRow {
            width: parent.width
            icon: page.on ? "nightlight" : "light_mode"
            title: "Night light"
            subtitle: NightLight.running
                      ? `Active · ${NightLight.backend}`
                      : (page.on ? "Enabled, waiting for its schedule" : "Off")

            MSwitch {
                checked: Settings.val("nightLight.enabled", false)
                onToggled: c => Settings.set("nightLight.enabled", c)
            }
        }

        MDivider { width: parent.width }

        // Temperature slider, tinted along its length so the scale reads.
        Column {
            width: parent.width
            spacing: Appearance.space.s
            opacity: Settings.val("nightLight.enabled", false) ? 1 : 0.45
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            MSliderRow {
                width: parent.width
                icon: "device_thermostat"
                title: "Colour temperature"
                subtitle: "Lower is warmer and more orange"
                from: 1700; to: 6500; stepSize: 100
                suffix: " K"
                enabledRow: Settings.val("nightLight.enabled", false)
                accent: NightLight.kelvinToColor(page.temp)
                value: page.temp
                onMoved: v => Settings.set("nightLight.temperature", v)
            }

            // the scale, as colour
            Rectangle {
                width: parent.width
                height: 14
                radius: 7
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: NightLight.kelvinToColor(1700) }
                    GradientStop { position: 0.35; color: NightLight.kelvinToColor(3000) }
                    GradientStop { position: 0.7; color: NightLight.kelvinToColor(5000) }
                    GradientStop { position: 1.0; color: NightLight.kelvinToColor(6500) }
                }
            }

            Row {
                width: parent.width
                Text {
                    text: "Warm"
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelSmall
                }
                Item { width: parent.width - 80; height: 1 }
                Text {
                    text: "Cool"
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelSmall
                }
            }
        }
    }

    // ---- schedule -----------------------------------------------------------
    MSection {
        width: parent.width
        visible: NightLight.available
        title: "Schedule"
        icon: "schedule"

        Repeater {
            model: NightLight.schedules

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: modelData.value === "off" ? "block"
                          : modelData.value === "manual" ? "all_inclusive"
                          : modelData.value === "sunset" ? "wb_twilight" : "more_time"
                    title: modelData.label
                    subtitle: modelData.hint
                    clickable: true
                    enabledRow: Settings.val("nightLight.enabled", false)
                    onClicked: Settings.set("nightLight.schedule", modelData.value)

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.width: 2
                        border.color: Settings.val("nightLight.schedule", "manual") === modelData.value
                                      ? Colors.primary : Colors.outline
                        Rectangle {
                            anchors.centerIn: parent
                            width: 12; height: 12; radius: 6
                            color: Colors.primary
                            visible: Settings.val("nightLight.schedule", "manual") === modelData.value
                        }
                    }
                }

                MDivider {
                    width: parent.width
                    visible: index < NightLight.schedules.length - 1
                }
            }
        }
    }

    // ---- custom hours -------------------------------------------------------
    MSection {
        width: parent.width
        visible: NightLight.available && Settings.val("nightLight.schedule", "") === "custom"
        title: "Custom hours"
        icon: "more_time"

        MRow {
            width: parent.width
            icon: "bedtime"
            title: "Turns on at"

            MSelect {
                width: 140
                model: page.hours
                value: Settings.val("nightLight.start", "20:00")
                onPicked: v => Settings.set("nightLight.start", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "wb_sunny"
            title: "Turns off at"

            MSelect {
                width: 140
                model: page.hours
                value: Settings.val("nightLight.end", "07:00")
                onPicked: v => Settings.set("nightLight.end", v)
            }
        }
    }

    // ---- location -----------------------------------------------------------
    MSection {
        width: parent.width
        visible: NightLight.available && Settings.val("nightLight.schedule", "") === "sunset"
        title: "Location"
        icon: "location_on"
        description: "Sunset and sunrise are computed from these coordinates. No network "
                   + "lookup happens — set them yourself."

        MRow {
            width: parent.width
            icon: "explore"
            title: "Latitude"

            MTextField {
                width: 160
                text: String(Settings.val("nightLight.latitude", 55.75))
                onEdited: t => {
                    const v = parseFloat(t)
                    if (!isNaN(v) && v >= -90 && v <= 90) Settings.set("nightLight.latitude", v)
                }
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "explore"
            title: "Longitude"

            MTextField {
                width: 160
                text: String(Settings.val("nightLight.longitude", 37.62))
                onEdited: t => {
                    const v = parseFloat(t)
                    if (!isNaN(v) && v >= -180 && v <= 180) Settings.set("nightLight.longitude", v)
                }
            }
        }
    }

    // Half-hour steps: enough control without a clock widget.
    readonly property var hours: {
        const out = []
        for (let h = 0; h < 24; h++)
            for (const m of ["00", "30"]) {
                const s = String(h).padStart(2, "0") + ":" + m
                out.push({ value: s, label: s })
            }
        return out
    }
}

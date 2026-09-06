import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Motion & density"
    subtitle: "How much room the interface takes, and how lively it feels."

    // ---- density -----------------------------------------------------------
    MSection {
        width: parent.width
        title: "Density"
        icon: "density_medium"
        description: "Scales every gap and padding in the shell. Compact fits more on "
                   + "small screens; comfortable is easier to hit with a trackpad."

        MRow {
            width: parent.width
            icon: "format_line_spacing"
            title: "Interface density"

            MSegmented {
                width: 320
                model: [
                    { value: 0, label: "Compact",     icon: "density_small" },
                    { value: 1, label: "Regular",     icon: "density_medium" },
                    { value: 2, label: "Comfortable", icon: "density_large" }
                ]
                value: Settings.val("appearance.density", 1)
                onPicked: v => Settings.set("appearance.density", v)
            }
        }

        MDivider { width: parent.width }

        // A live specimen so the choice is visible rather than abstract.
        Column {
            width: parent.width
            spacing: Appearance.space.s

            Text {
                text: "Preview"
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelLarge
            }

            Rectangle {
                width: parent.width
                height: specimen.implicitHeight + Appearance.space.l * 2
                radius: Appearance.radius.m
                color: Colors.surfaceContainerHighest

                Column {
                    id: specimen
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.space.l
                    spacing: Appearance.space.m

                    Row {
                        spacing: Appearance.space.s
                        MChip { label: "Chip"; selected: true }
                        MChip { label: "Another" }
                        MButton {
                            label: "Button"
                            bg: Colors.primaryContainer
                            fg: Colors.on.primaryContainer
                            hpad: Appearance.space.l
                        }
                        MSwitch { anchors.verticalCenter: parent.verticalCenter; checked: true }
                    }
                    MSlider { width: parent.width; value: 0.6 }
                }
            }
        }
    }

    // ---- motion ------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Animation"
        icon: "animation"
        description: "The shell animates with springs rather than fixed curves, so the "
                   + "speed control changes how stiff those springs are."

        MRow {
            width: parent.width
            icon: "play_circle"
            title: "Animations"
            subtitle: Settings.val("appearance.animations", true)
                      ? "Panels, switches and pages animate"
                      : "Everything snaps instantly — cheapest option in a VM"

            MSwitch {
                checked: Settings.val("appearance.animations", true)
                onToggled: c => Settings.set("appearance.animations", c)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "speed"
            title: "Animation speed"
            subtitle: "Below 1 is faster, above 1 is more languid"
            from: 0.5; to: 2.0; stepSize: 0.1; decimals: 1; suffix: "×"
            enabledRow: Settings.val("appearance.animations", true)
            value: Settings.val("appearance.animationScale", 1.0)
            onMoved: v => Settings.set("appearance.animationScale", v)
        }

        MDivider { width: parent.width }

        // Something that actually moves, so the speed setting is legible.
        Column {
            width: parent.width
            spacing: Appearance.space.s

            Text {
                text: "Try it"
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelLarge
            }

            Rectangle {
                id: track
                width: parent.width
                height: 64
                radius: Appearance.radius.m
                color: Colors.surfaceContainerHighest

                property bool flipped: false

                Rectangle {
                    width: 44; height: 44
                    radius: track.flipped ? 22 : Appearance.radius.s
                    anchors.verticalCenter: parent.verticalCenter
                    x: track.flipped ? track.width - width - 10 : 10
                    color: track.flipped ? Colors.tertiary : Colors.primary

                    Behavior on x {
                        SpringAnimation {
                            spring: Motion.spatial.spring; damping: Motion.spatial.damping
                            mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                        }
                    }
                    Behavior on radius { NumberAnimation { duration: Motion.durMedium } }
                    Behavior on color { ColorAnimation { duration: Motion.durMedium } }

                    MIcon {
                        anchors.centerIn: parent
                        name: track.flipped ? "bolt" : "touch_app"
                        size: 20
                        color: Colors.on.primary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: track.flipped = !track.flipped
                }
            }
        }
    }

    // ---- compositor motion ---------------------------------------------------
    MSection {
        width: parent.width
        title: "Compositor animation"
        icon: "view_carousel"
        description: "niri's own window and workspace animations, separate from the shell's."

        MRow {
            width: parent.width
            icon: "animation"
            title: "niri animations"
            subtitle: "Window opening, workspace switching, the overview"

            MSwitch {
                checked: Settings.val("niri.animationsEnabled", true)
                onToggled: c => Settings.set("niri.animationsEnabled", c)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "slow_motion_video"
            title: "niri animation slowdown"
            subtitle: "1.0 is normal speed; higher is slower"
            from: 0.3; to: 3.0; stepSize: 0.1; decimals: 1; suffix: "×"
            enabledRow: Settings.val("niri.animationsEnabled", true)
            value: Settings.val("niri.animationSlowdown", 1.0)
            onMoved: v => Settings.set("niri.animationSlowdown", v)
        }
    }
}

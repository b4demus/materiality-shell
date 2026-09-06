import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Mouse & touchpad"
    subtitle: "libinput settings, written into niri's input configuration."
    maxWidth: 880

    readonly property var accelProfiles: [
        { value: "adaptive", label: "Adaptive", hint: "Speed depends on how fast you move" },
        { value: "flat",     label: "Flat",     hint: "One-to-one, no acceleration" }
    ]

    // ---- mouse --------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Mouse"
        icon: "mouse"

        MSliderRow {
            width: parent.width
            icon: "speed"
            title: "Pointer speed"
            subtitle: "Negative is slower than the system default"
            from: -1; to: 1; stepSize: 0.05; decimals: 2
            value: Settings.val("input.mouse.speed", 0)
            onMoved: v => Settings.set("input.mouse.speed", v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "trending_up"
            title: "Acceleration"

            MSegmented {
                width: 220
                model: page.accelProfiles.map(p => ({ value: p.value, label: p.label }))
                value: Settings.val("input.mouse.accelProfile", "adaptive")
                onPicked: v => Settings.set("input.mouse.accelProfile", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "swap_vert"
            title: "Natural scrolling"
            subtitle: "Content follows your fingers instead of the scrollbar"

            MSwitch {
                checked: Settings.val("input.mouse.naturalScroll", false)
                onToggled: c => Settings.set("input.mouse.naturalScroll", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "adjust"
            title: "Middle-click emulation"
            subtitle: "Press left and right together for a middle click"

            MSwitch {
                checked: Settings.val("input.mouse.middleEmulation", false)
                onToggled: c => Settings.set("input.mouse.middleEmulation", c)
            }
        }
    }

    // ---- touchpad -----------------------------------------------------------
    MSection {
        width: parent.width
        title: "Touchpad"
        icon: "touch_app"

        MRow {
            width: parent.width
            icon: "touch_app"
            title: "Touchpad"

            MSwitch {
                checked: Settings.val("input.touchpad.enabled", true)
                onToggled: c => Settings.set("input.touchpad.enabled", c)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "speed"
            title: "Pointer speed"
            from: -1; to: 1; stepSize: 0.05; decimals: 2
            enabledRow: Settings.val("input.touchpad.enabled", true)
            value: Settings.val("input.touchpad.speed", 0)
            onMoved: v => Settings.set("input.touchpad.speed", v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "touch_app"
            title: "Tap to click"
            enabledRow: Settings.val("input.touchpad.enabled", true)

            MSwitch {
                checked: Settings.val("input.touchpad.tap", true)
                enabledSwitch: Settings.val("input.touchpad.enabled", true)
                onToggled: c => Settings.set("input.touchpad.tap", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "swap_vert"
            title: "Natural scrolling"
            enabledRow: Settings.val("input.touchpad.enabled", true)

            MSwitch {
                checked: Settings.val("input.touchpad.naturalScroll", true)
                enabledSwitch: Settings.val("input.touchpad.enabled", true)
                onToggled: c => Settings.set("input.touchpad.naturalScroll", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "edit_off"
            title: "Disable while typing"
            subtitle: "Stops the heel of your hand moving the cursor"
            enabledRow: Settings.val("input.touchpad.enabled", true)

            MSwitch {
                checked: Settings.val("input.touchpad.dwt", true)
                enabledSwitch: Settings.val("input.touchpad.enabled", true)
                onToggled: c => Settings.set("input.touchpad.dwt", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "swipe"
            title: "Scroll method"
            enabledRow: Settings.val("input.touchpad.enabled", true)

            MSelect {
                width: 200
                enabledSelect: Settings.val("input.touchpad.enabled", true)
                model: [
                    { value: "two-finger",     label: "Two fingers" },
                    { value: "edge",           label: "Edge" },
                    { value: "on-button-down", label: "Hold a button" },
                    { value: "no-scroll",      label: "No scrolling" }
                ]
                value: Settings.val("input.touchpad.scrollMethod", "two-finger")
                onPicked: v => Settings.set("input.touchpad.scrollMethod", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "ads_click"
            title: "Click method"
            enabledRow: Settings.val("input.touchpad.enabled", true)

            MSelect {
                width: 200
                enabledSelect: Settings.val("input.touchpad.enabled", true)
                model: [
                    { value: "clickfinger",  label: "Fingers",
                      hint: "One, two or three fingers for left, right, middle" },
                    { value: "button-areas", label: "Areas",
                      hint: "Bottom-left and bottom-right zones" }
                ]
                value: Settings.val("input.touchpad.clickMethod", "clickfinger")
                onPicked: v => Settings.set("input.touchpad.clickMethod", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "trending_up"
            title: "Acceleration"
            enabledRow: Settings.val("input.touchpad.enabled", true)

            MSegmented {
                width: 220
                model: page.accelProfiles.map(p => ({ value: p.value, label: p.label }))
                value: Settings.val("input.touchpad.accelProfile", "adaptive")
                onPicked: v => Settings.set("input.touchpad.accelProfile", v)
            }
        }
    }

    // ---- a place to feel the settings ---------------------------------------
    MSection {
        width: parent.width
        title: "Test area"
        icon: "gesture"
        description: "Move, click and scroll here to feel the current settings."

        Rectangle {
            width: parent.width
            height: 140
            radius: Appearance.radius.m
            color: Colors.surfaceContainerHighest
            clip: true

            Rectangle {
                id: dot
                width: 26; height: 26; radius: 13
                color: testArea.pressed ? Colors.tertiary : Colors.primary
                x: 20; y: 20
                Behavior on color { ColorAnimation { duration: Motion.durShort } }
            }

            Text {
                anchors.centerIn: parent
                text: testArea.containsMouse ? `scroll: ${testArea.scrolled}` : "Move the pointer here"
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyMedium
            }

            MouseArea {
                id: testArea
                property int scrolled: 0
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: mouse => {
                    dot.x = Math.max(0, Math.min(width - dot.width, mouse.x - dot.width / 2))
                    dot.y = Math.max(0, Math.min(height - dot.height, mouse.y - dot.height / 2))
                }
                onWheel: w => scrolled += w.angleDelta.y > 0 ? 1 : -1
            }
        }
    }
}

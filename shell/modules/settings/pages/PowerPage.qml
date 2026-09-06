import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Power"
    subtitle: "Battery, performance profile and what happens when the machine idles."
    maxWidth: 880

    // ---- battery ------------------------------------------------------------
    MCard {
        width: parent.width
        visible: Power.hasBattery
        tone: Colors.surfaceContainerLow

        Row {
            width: parent.width
            spacing: Appearance.space.l

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 72; height: 72

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.radius.l
                    color: Power.percent <= 15 && !Power.charging
                           ? Colors.errorContainer : Colors.primaryContainer
                    Behavior on color { ColorAnimation { duration: Motion.durMedium } }
                }
                MIcon {
                    anchors.centerIn: parent
                    name: Bat.icon
                    size: 30
                    fill: 1
                    color: Power.percent <= 15 && !Power.charging
                           ? Colors.on.errorContainer : Colors.on.primaryContainer
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 72 - Appearance.space.l
                spacing: 4

                Text {
                    text: `${Math.round(Power.percent)}%`
                    color: Colors.on.surface
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.headlineMedium
                    font.weight: Appearance.font.weightMedium
                }
                Text {
                    text: Power.batteryDetail
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodyMedium
                }
                Text {
                    visible: Power.health > 0
                    text: `Health ${Math.round(Power.health)}%`
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodySmall
                }
            }
        }
    }

    MCard {
        width: parent.width
        visible: !Power.hasBattery
        tone: Colors.surfaceContainerLow

        Row {
            width: parent.width
            spacing: Appearance.space.l

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "power"
                size: 28
                color: Colors.primary
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "Running on mains power"
                    color: Colors.on.surface
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodyLarge
                    font.weight: Appearance.font.weightMedium
                }
                Text {
                    text: "No battery is present, so the battery settings below do nothing here."
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodySmall
                }
            }
        }
    }

    // ---- profile ------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Power profile"
        icon: "speed"
        description: "Handled by power-profiles-daemon, the same setting GNOME uses."

        Repeater {
            model: Power.profileList

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: modelData.icon
                    title: modelData.label
                    subtitle: modelData.hint
                    clickable: true
                    onClicked: Power.setProfile(modelData.value)

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.width: 2
                        border.color: Power.profile === modelData.value ? Colors.primary : Colors.outline
                        Rectangle {
                            anchors.centerIn: parent
                            width: 12; height: 12; radius: 6
                            color: Colors.primary
                            visible: Power.profile === modelData.value
                        }
                    }
                }

                MDivider { width: parent.width; visible: index < Power.profileList.length - 1 }
            }
        }
    }

    // ---- idle ---------------------------------------------------------------
    MSection {
        width: parent.width
        title: "When idle"
        icon: "schedule"
        description: Power.idleAvailable
                     ? "Timers run through swayidle, which the shell starts and stops for you."
                     : ""

        MEmptyState {
            width: parent.width
            visible: !Power.idleAvailable
            icon: "timer_off"
            title: "Idle timers need swayidle"
            message: "niri has no built-in idle timer, so blanking, locking and suspending "
                   + "on idle are delegated to swayidle."
            code: Power.idleHint
            actionLabel: "Check again"
            onActionClicked: Power.refreshIdle()
        }

        MRow {
            width: parent.width
            visible: Power.idleAvailable
            icon: "brightness_low"
            title: "Blank the screen after"

            MSelect {
                width: 200
                model: Power.timeoutChoices
                value: Settings.val("power.screenTimeoutSec", 600)
                onPicked: v => Settings.set("power.screenTimeoutSec", v)
            }
        }

        MDivider { width: parent.width; visible: Power.idleAvailable }

        MRow {
            width: parent.width
            visible: Power.idleAvailable
            icon: "lock_clock"
            title: "Lock the session after"

            MSelect {
                width: 200
                model: Power.timeoutChoices
                value: Settings.val("power.lockTimeoutSec", 900)
                onPicked: v => Settings.set("power.lockTimeoutSec", v)
            }
        }

        MDivider { width: parent.width; visible: Power.idleAvailable }

        MRow {
            width: parent.width
            visible: Power.idleAvailable
            icon: "bedtime"
            title: "Suspend after"

            MSelect {
                width: 200
                model: Power.timeoutChoices
                value: Settings.val("power.suspendTimeoutSec", 1800)
                onPicked: v => Settings.set("power.suspendTimeoutSec", v)
            }
        }
    }

    // ---- buttons & lid --------------------------------------------------------
    MSection {
        width: parent.width
        title: "Buttons"
        icon: "toggle_on"

        MRow {
            width: parent.width
            icon: "laptop"
            title: "When the lid closes"

            MSelect {
                width: 200
                model: [
                    { value: "suspend", label: "Suspend" },
                    { value: "lock",    label: "Lock only" },
                    { value: "nothing", label: "Do nothing" }
                ]
                value: Settings.val("power.lidClose", "suspend")
                onPicked: v => Settings.set("power.lidClose", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "power_settings_new"
            title: "Power button"

            MSelect {
                width: 200
                model: [
                    { value: "menu",     label: "Show a menu" },
                    { value: "suspend",  label: "Suspend" },
                    { value: "poweroff", label: "Power off" },
                    { value: "nothing",  label: "Do nothing" }
                ]
                value: Settings.val("power.powerButton", "menu")
                onPicked: v => Settings.set("power.powerButton", v)
            }
        }
    }

    // ---- battery behaviour ----------------------------------------------------
    MSection {
        width: parent.width
        visible: Power.hasBattery
        title: "Low battery"
        icon: "battery_alert"

        MSliderRow {
            width: parent.width
            icon: "battery_alert"
            title: "Warn below"
            from: 5; to: 40; stepSize: 1; suffix: "%"
            value: Settings.val("power.lowBatteryPercent", 15)
            onMoved: v => Settings.set("power.lowBatteryPercent", v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "bolt"
            title: "And then"

            MSelect {
                width: 220
                model: [
                    { value: "notify",    label: "Just notify me" },
                    { value: "powersave", label: "Switch to power saver" },
                    { value: "suspend",   label: "Suspend" }
                ]
                value: Settings.val("power.lowBatteryAction", "notify")
                onPicked: v => Settings.set("power.lowBatteryAction", v)
            }
        }
    }

    // ---- session --------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Session"
        icon: "logout"

        Flow {
            width: parent.width
            spacing: Appearance.space.s

            MButton {
                icon: "lock"
                label: "Lock"
                bg: Colors.surfaceContainerHighest
                fg: Colors.on.surfaceVariant
                hpad: Appearance.space.l
                onClicked: Power.lock()
            }
            MButton {
                icon: "bedtime"
                label: "Suspend"
                bg: Colors.surfaceContainerHighest
                fg: Colors.on.surfaceVariant
                hpad: Appearance.space.l
                onClicked: Power.suspend()
            }
            MButton {
                icon: "logout"
                label: "Log out"
                bg: Colors.surfaceContainerHighest
                fg: Colors.on.surfaceVariant
                hpad: Appearance.space.l
                onClicked: confirm.ask("Log out?", "Unsaved work in open applications will be lost.",
                                       "Log out", () => Power.logOut())
            }
            MButton {
                icon: "restart_alt"
                label: "Restart"
                bg: Colors.surfaceContainerHighest
                fg: Colors.on.surfaceVariant
                hpad: Appearance.space.l
                onClicked: confirm.ask("Restart now?", "", "Restart", () => Power.reboot())
            }
            MButton {
                icon: "power_settings_new"
                label: "Power off"
                bg: Colors.errorContainer
                fg: Colors.on.errorContainer
                hpad: Appearance.space.l
                onClicked: confirm.ask("Power off?", "", "Power off", () => Power.powerOff())
            }
        }
    }

    MDialog {
        id: confirm
        property var action: null

        function ask(t, m, label, fn) {
            title = t
            message = m
            confirmText = label
            action = fn
            open = true
        }

        icon: "help"
        destructive: true
        onConfirmed: if (action) action()
    }
}

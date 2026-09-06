import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Notifications"
    subtitle: "How notification cards behave, and which applications may send them."
    maxWidth: 880

    readonly property var perApp: Settings.val("notifications.perApp", {})

    function setApp(name, allowed) {
        const next = Object.assign({}, perApp)
        next[name] = allowed
        Settings.set("notifications.perApp", next)
    }

    MSection {
        width: parent.width
        title: "General"
        icon: "notifications"

        MRow {
            width: parent.width
            icon: Settings.val("notifications.enabled", true) ? "notifications" : "notifications_off"
            title: "Notifications"
            subtitle: "Master switch for the on-screen cards"

            MSwitch {
                checked: Settings.val("notifications.enabled", true)
                onToggled: c => Settings.set("notifications.enabled", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "do_not_disturb_on"
            title: "Do not disturb"
            subtitle: "Notifications are collected in history instead of popping up"

            MSwitch {
                checked: Settings.val("notifications.dnd", false)
                onToggled: c => Settings.set("notifications.dnd", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "lock"
            title: "Show on the lock screen"
            subtitle: "Card contents are visible while the session is locked"

            MSwitch {
                checked: Settings.val("notifications.showOnLockscreen", false)
                onToggled: c => Settings.set("notifications.showOnLockscreen", c)
            }
        }
    }

    MSection {
        width: parent.width
        title: "Appearance"
        icon: "space_dashboard"

        MRow {
            width: parent.width
            icon: "picture_in_picture"
            title: "Position"

            MSelect {
                width: 220
                model: [
                    { value: "top-right",    label: "Top right" },
                    { value: "top-center",   label: "Top centre" },
                    { value: "top-left",     label: "Top left" },
                    { value: "bottom-right", label: "Bottom right" },
                    { value: "bottom-center", label: "Bottom centre" },
                    { value: "bottom-left",  label: "Bottom left" }
                ]
                value: Settings.val("notifications.position", "top-right")
                onPicked: v => Settings.set("notifications.position", v)
            }
        }

        MDivider { width: parent.width }

        MSliderRow {
            width: parent.width
            icon: "timer"
            title: "How long a card stays"
            subtitle: "Urgent notifications ignore this and stay until dismissed"
            from: 2; to: 30; stepSize: 1; suffix: " s"
            value: Settings.val("notifications.durationSec", 6)
            onMoved: v => Settings.set("notifications.durationSec", v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "volume_up"
            title: "Play a sound"

            MSwitch {
                checked: Settings.val("notifications.sound", false)
                onToggled: c => Settings.set("notifications.sound", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "history"
            title: "History size"
            subtitle: "How many past notifications to keep"

            MStepper {
                value: Settings.val("notifications.historyLimit", 100)
                from: 0; to: 500; stepSize: 25
                onChanged: v => Settings.set("notifications.historyLimit", v)
            }
        }
    }

    // ---- per application ------------------------------------------------------
    MSection {
        width: parent.width
        title: "Applications"
        icon: "apps"
        description: "Applications appear here once they have sent a notification. "
                   + "Turning one off silences it without silencing the rest."

        Repeater {
            model: Object.keys(page.perApp).sort()

            delegate: Column {
                required property string modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: "apps"
                    title: Apps.nameFor(modelData)
                    subtitle: modelData

                    MSwitch {
                        checked: page.perApp[modelData] !== false
                        onToggled: c => page.setApp(modelData, c)
                    }
                }

                MDivider {
                    width: parent.width
                    visible: index < Object.keys(page.perApp).length - 1
                }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Object.keys(page.perApp).length === 0
            icon: "notifications_none"
            title: "No applications yet"
            message: "The list fills in as apps send their first notification."
        }
    }
}

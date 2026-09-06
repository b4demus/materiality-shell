import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/components"
import "root:/services"

// Alarm / timer popup, opened by clicking the bar time. Two segmented tabs;
// state is held in the TimeTools singleton so it survives the popup closing.
PanelWindow {
    id: root
    visible: Bus.timePopupOpen
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-timepopup"
    WlrLayershell.keyboardFocus: Bus.timePopupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    property int tab: 0            // 0 = timer, 1 = alarm
    property int draftH: 7
    property int draftM: 0

    function pad(n) { return ("0" + n).slice(-2) }
    function fmtDur(s) {
        s = Math.max(0, Math.floor(s))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const sec = s % 60
        return h > 0
            ? h + ":" + pad(m) + ":" + pad(sec)
            : pad(m) + ":" + pad(sec)
    }

    Item {
        anchors.fill: parent
        focus: Bus.timePopupOpen
        Keys.onEscapePressed: Bus.timePopupOpen = false

        MouseArea { anchors.fill: parent; onClicked: Bus.timePopupOpen = false }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Bus.timePopupOpen
                ? Appearance.barInsetTop
                : -(height + 24)
            width: 340
            height: col.implicitHeight + Appearance.space.l * 2
            radius: Appearance.radius.xl
            color: Colors.surfaceContainerHigh
            clip: true

            opacity: Bus.timePopupOpen ? 1 : 0
            Behavior on anchors.topMargin {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            MouseArea { anchors.fill: parent }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.space.l
                spacing: Appearance.space.l

                // ---- segmented tabs -------------------------------
                Row {
                    width: parent.width
                    height: 38

                    Repeater {
                        model: [
                            { k: "Timer", i: "timer" },
                            { k: "Alarm", i: "alarm" }
                        ]
                        delegate: Rectangle {
                            id: seg
                            required property var modelData
                            required property int index
                            readonly property bool sel: root.tab === index
                            width: parent.width / 2
                            height: 38
                            color: sel ? Colors.secondaryContainer : Colors.surfaceContainerHighest
                            radius: Appearance.radius.full
                            Behavior on color { ColorAnimation { duration: Motion.durShort } }

                            Row {
                                anchors.centerIn: parent
                                spacing: Appearance.space.xs
                                MIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: seg.modelData.i
                                    size: 18
                                    fill: seg.sel ? 1 : 0
                                    color: seg.sel ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: seg.modelData.k
                                    color: seg.sel ? Colors.on.secondaryContainer : Colors.on.surfaceVariant
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelLarge
                                    font.weight: Appearance.font.weightMedium
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.tab = seg.index
                            }
                        }
                    }
                }

                // ================= TIMER =========================
                Column {
                    width: parent.width
                    spacing: Appearance.space.l
                    visible: root.tab === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.fmtDur(TimeTools.timerRemaining > 0
                            ? TimeTools.timerRemaining
                            : TimeTools.timerDuration)
                        color: Colors.on.surface
                        font.family: Appearance.clockFamily
                        font.pixelSize: Appearance.font.displaySmall
                        font.weight: Appearance.font.weightMedium
                    }

                    MSlider {
                        width: parent.width
                        interactive: false
                        activeColor: Colors.tertiary
                        value: TimeTools.timerProgress
                    }

                    // fine adjust — minutes and seconds
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Appearance.space.s
                        opacity: TimeTools.timerRunning ? 0.4 : 1

                        Repeater {
                            model: [
                                { t: "-1m",  d: -60 },
                                { t: "-10s", d: -10 },
                                { t: "+10s", d: 10 },
                                { t: "+1m",  d: 60 }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                height: 30
                                width: adjLabel.implicitWidth + Appearance.space.m
                                radius: Appearance.radius.full
                                color: Colors.surfaceContainerHighest
                                border.width: 1
                                border.color: Colors.outlineVariant

                                Text {
                                    id: adjLabel
                                    anchors.centerIn: parent
                                    text: modelData.t
                                    color: Colors.on.surfaceVariant
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelMedium
                                    font.weight: Appearance.font.weightMedium
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !TimeTools.timerRunning
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TimeTools.timerBump(modelData.d)
                                }
                            }
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: Appearance.space.s

                        Repeater {
                            model: [1, 5, 10, 15, 25, 45]
                            delegate: Rectangle {
                                required property var modelData
                                height: 32
                                width: presetLabel.implicitWidth + Appearance.space.l
                                radius: Appearance.radius.full
                                color: Colors.surfaceContainerHighest
                                border.width: 1
                                border.color: Colors.outlineVariant

                                Text {
                                    id: presetLabel
                                    anchors.centerIn: parent
                                    text: modelData + "m"
                                    color: Colors.on.surfaceVariant
                                    font.family: Appearance.fontFamily
                                    font.pixelSize: Appearance.font.labelMedium
                                    font.weight: Appearance.font.weightMedium
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TimeTools.timerStart(modelData * 60)
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Appearance.space.m

                        MButton {
                            icon: TimeTools.timerRunning ? "pause" : "play_arrow"
                            label: TimeTools.timerRunning ? "Pause" : "Start"
                            iconSize: 20
                            bg: Colors.primaryContainer
                            fg: Colors.on.primaryContainer
                            onClicked: TimeTools.timerToggle()
                        }
                        MButton {
                            icon: "restart_alt"
                            label: "Reset"
                            iconSize: 20
                            bg: Colors.secondaryContainer
                            fg: Colors.on.secondaryContainer
                            onClicked: TimeTools.timerReset()
                        }
                    }
                }

                // ================= ALARM =========================
                Column {
                    width: parent.width
                    spacing: Appearance.space.l
                    visible: root.tab === 1

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Appearance.space.m

                        Column {
                            spacing: Appearance.space.xs
                            MButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: "keyboard_arrow_up"; iconSize: 20
                                onClicked: root.draftH = (root.draftH + 1) % 24
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.pad(root.draftH)
                                color: Colors.on.surface
                                font.family: Appearance.clockFamily
                                font.pixelSize: Appearance.font.headlineSmall
                            }
                            MButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: "keyboard_arrow_down"; iconSize: 20
                                onClicked: root.draftH = (root.draftH + 23) % 24
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ":"
                            color: Colors.on.surfaceVariant
                            font.family: Appearance.clockFamily
                            font.pixelSize: Appearance.font.headlineSmall
                        }

                        Column {
                            spacing: Appearance.space.xs
                            MButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: "keyboard_arrow_up"; iconSize: 20
                                onClicked: root.draftM = (root.draftM + 5) % 60
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.pad(root.draftM)
                                color: Colors.on.surface
                                font.family: Appearance.clockFamily
                                font.pixelSize: Appearance.font.headlineSmall
                            }
                            MButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: "keyboard_arrow_down"; iconSize: 20
                                onClicked: root.draftM = (root.draftM + 55) % 60
                            }
                        }

                        MButton {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "add_alarm"; label: "Add"; iconSize: 20
                            bg: Colors.primaryContainer
                            fg: Colors.on.primaryContainer
                            onClicked: TimeTools.addAlarm(root.draftH, root.draftM)
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Appearance.space.s

                        Text {
                            visible: TimeTools.alarms.length === 0
                            width: parent.width
                            text: "No alarms yet — set a time above and hit Add."
                            wrapMode: Text.Wrap
                            color: Colors.on.surfaceVariant
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelMedium
                        }

                        Repeater {
                            model: TimeTools.alarms
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 46
                                radius: Appearance.radius.m
                                color: Colors.surfaceContainerHighest

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Appearance.space.m
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.pad(modelData.hour) + ":" + root.pad(modelData.minute)
                                    color: modelData.enabled ? Colors.on.surface : Colors.on.surfaceVariant
                                    font.family: Appearance.clockFamily
                                    font.pixelSize: Appearance.font.titleMedium
                                    opacity: modelData.enabled ? 1 : 0.55
                                }

                                Row {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Appearance.space.xs
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    MButton {
                                        icon: modelData.enabled ? "toggle_on" : "toggle_off"
                                        iconSize: 24
                                        iconFill: 1
                                        fg: modelData.enabled ? Colors.primary : Colors.on.surfaceVariant
                                        onClicked: TimeTools.toggleAlarm(modelData.id)
                                    }
                                    MButton {
                                        icon: "delete"
                                        iconSize: 18
                                        fg: Colors.on.surfaceVariant
                                        onClicked: TimeTools.removeAlarm(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "root:/config"
import "root:/components"
import "root:/services"

// The lock UI itself (shared by the real WlSessionLockSurface and the preview).
// Solid tonal fill that follows the active scheme, stacked clock, quick-settings
// tiles and a PAM auth card with Pixel-style dot masking.
Item {
    id: root

    // becomes true while the lock is actually shown → focus + reset
    property bool active: false
    signal unlocked()

    property string errorText: ""
    property bool busy: false

    onActiveChanged: if (active) {
        errorText = ""
        pwInput.clear()
        pwInput.forceActiveFocus()
    }

    function submit() {
        if (busy || pwInput.text.length === 0)
            return
        errorText = ""
        busy = true
        if (!pam.start()) {
            busy = false
            errorText = "Could not start PAM"
        }
    }
    function run(parts) { proc.command = parts; proc.running = true }

    Rectangle { anchors.fill: parent; color: Colors.background }

    SystemClock { id: clock; precision: SystemClock.Seconds }
    Process { id: proc }

    PamContext {
        id: pam
        config: "swaylock"
        configDirectory: "/etc/pam.d"

        onPamMessage: if (pam.responseRequired) pam.respond(pwInput.text)
        onCompleted: result => {
            root.busy = false
            if (result === PamResult.Success) {
                root.errorText = ""
                pwInput.clear()
                root.unlocked()
            } else {
                root.errorText = "Incorrect password"
                pwInput.clear()
                shake.restart()
            }
        }
        onError: e => {
            root.busy = false
            root.errorText = "Authentication error"
            pwInput.clear()
        }
    }

    component LockTile: Rectangle {
        id: tile
        property string glyph: ""
        property string title: ""
        property string sub: ""
        signal activated()

        height: 58
        radius: 20
        color: Colors.surfaceContainerHighest

        // Icon only — the POWER / SESSION / REBOOT / SLEEP wording is gone.
        Rectangle {
            anchors.centerIn: parent
            width: 34; height: 34; radius: 17
            color: Colors.primaryContainer
            MIcon {
                anchors.centerIn: parent
                name: tile.glyph
                size: 19
                fill: 1
                color: Colors.on.primaryContainer
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.on.surface
            opacity: tma.pressed ? Appearance.statePress
                     : tma.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
        MouseArea {
            id: tma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.activated()
        }
    }

    // ---- layout --------------------------------------------------------
    Item {
        anchors.fill: parent
        focus: true
        Keys.forwardTo: [pwInput]
        Component.onCompleted: pwInput.forceActiveFocus()

        Row {
            anchors.centerIn: parent
            spacing: 76

            // ===== clock =====
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: Qt.formatDateTime(clock.date, "HH")
                    color: Colors.primary
                    font.family: Appearance.clockFamily
                    font.pixelSize: 150
                    font.weight: Appearance.font.weightMedium
                    height: 118
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Colors.primary
                    font.family: Appearance.clockFamily
                    font.pixelSize: 150
                    font.weight: Appearance.font.weightMedium
                    height: 118
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: dateLabel.implicitWidth + Appearance.space.l * 2
                    height: 30
                    radius: Appearance.radius.full
                    color: Colors.surfaceContainerHigh
                    Text {
                        id: dateLabel
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, "dddd, MMM d").toUpperCase()
                        color: Colors.on.surfaceVariant
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.labelMedium
                        font.weight: Appearance.font.weightMedium
                        font.letterSpacing: 1
                    }
                }
            }

            // ===== quick settings + auth =====
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: 420
                spacing: Appearance.space.m

                Grid {
                    id: grid
                    width: parent.width
                    columns: 2
                    columnSpacing: Appearance.space.m
                    rowSpacing: Appearance.space.m
                    readonly property real tileW: (width - columnSpacing) / 2

                    LockTile {
                        width: grid.tileW
                        glyph: "power_settings_new"; title: "POWER"; sub: "SHUT DOWN"
                        onActivated: root.run(["systemctl", "poweroff"])
                    }
                    LockTile {
                        width: grid.tileW
                        glyph: "logout"; title: "SESSION"; sub: "NIRI"
                        onActivated: root.run(["niri", "msg", "action", "quit", "-s"])
                    }
                    LockTile {
                        width: grid.tileW
                        glyph: "restart_alt"; title: "REBOOT"; sub: "RESTART"
                        onActivated: root.run(["systemctl", "reboot"])
                    }
                    LockTile {
                        width: grid.tileW
                        glyph: "bedtime"; title: "SLEEP"; sub: "SUSPEND"
                        onActivated: root.run(["systemctl", "suspend"])
                    }
                }

                // ---- auth card ----
                Rectangle {
                    id: card
                    width: parent.width
                    implicitHeight: cardCol.implicitHeight + Appearance.space.l * 2
                    height: implicitHeight
                    radius: Appearance.radius.xl
                    color: Colors.surfaceContainerHigh

                    transform: Translate { id: shakeT }
                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: shakeT; property: "x"; to: 10; duration: 45 }
                        NumberAnimation { target: shakeT; property: "x"; to: -10; duration: 45 }
                        NumberAnimation { target: shakeT; property: "x"; to: 6; duration: 45 }
                        NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 45 }
                    }

                    Column {
                        id: cardCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Appearance.space.l
                        spacing: Appearance.space.m

                        // password field
                        Rectangle {
                            width: parent.width
                            height: 46
                            radius: Appearance.radius.full
                            color: Colors.surfaceContainerHighest
                            border.width: pwInput.activeFocus ? 2 : 0
                            border.color: Colors.primary

                            TextInput {
                                id: pwInput
                                anchors.fill: parent
                                anchors.leftMargin: Appearance.space.l
                                anchors.rightMargin: Appearance.space.l
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.on.surface
                                font.family: Appearance.clockFamily
                                font.pixelSize: 20
                                font.letterSpacing: 4
                                echoMode: TextInput.Password
                                passwordCharacter: "●"  // ● solid dot, like recent Android; masks immediately
                                selectByMouse: false
                                clip: true
                                enabled: !root.busy
                                cursorVisible: activeFocus && text.length > 0
                                onAccepted: root.submit()
                            }
                        }

                        // footer
                        Item {
                            width: parent.width
                            height: 40

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: (Quickshell.env("USER") || "user").toUpperCase()
                                color: Colors.on.surfaceVariant
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.labelMedium
                                font.weight: Appearance.font.weightMedium
                                font.letterSpacing: 1
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 150; height: 40
                                radius: Appearance.radius.full
                                color: Colors.primary
                                opacity: (root.busy || pwInput.text.length === 0) ? 0.55 : 1
                                Behavior on opacity { NumberAnimation { duration: Motion.durShort } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Appearance.space.s
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.busy ? "CHECKING" : "UNLOCK"
                                        color: Colors.on.primary
                                        font.family: Appearance.fontFamily
                                        font.pixelSize: Appearance.font.labelMedium
                                        font.weight: Appearance.font.weightBold
                                        font.letterSpacing: 1
                                    }
                                    MIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !root.busy
                                        name: "arrow_forward"
                                        size: 16
                                        color: Colors.on.primary
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Colors.on.primary
                                    opacity: ubma.pressed ? Appearance.statePress
                                             : ubma.containsMouse ? Appearance.stateHover : 0
                                    Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                                }
                                MouseArea {
                                    id: ubma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.submit()
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: root.errorText !== ""
                            text: root.errorText
                            color: Colors.error
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelSmall
                            font.weight: Appearance.font.weightMedium
                        }
                    }
                }
            }
        }
    }
}

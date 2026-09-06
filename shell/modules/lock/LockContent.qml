pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "root:/config"
import "root:/components"
import "root:/services"

// The lock UI itself (shared by the real WlSessionLockSurface and the preview).
// One centred column: stacked clock, date, the password field, session actions.
// The password is masked with Material shapes rather than dots — each keystroke
// springs a different silhouette in and settles it from the accent to a muted
// tone, the way recent Android does it.
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
                root.errorText = "Wrong password"
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

    // A round, icon-only session action.
    component LockAction: Rectangle {
        id: act
        property string glyph: ""
        signal activated()

        implicitWidth: 52
        implicitHeight: 52
        radius: height / 2
        color: Colors.surfaceContainerHigh

        MIcon {
            anchors.centerIn: parent
            name: act.glyph
            size: 21
            fill: 1
            color: Colors.on.surfaceVariant
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.on.surface
            opacity: ama.pressed ? Appearance.statePress
                     : ama.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        }
        MouseArea {
            id: ama
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: act.activated()
        }
    }

    // ---- layout --------------------------------------------------------
    Item {
        anchors.fill: parent
        focus: true
        Keys.forwardTo: [pwInput]
        Component.onCompleted: pwInput.forceActiveFocus()

        Column {
            anchors.centerIn: parent
            spacing: Appearance.space.xl

            // ===== clock =====
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: -18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH")
                    color: Colors.primary
                    font.family: Appearance.clockFamily
                    font.pixelSize: 132
                    font.weight: Appearance.font.weightMedium
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Colors.primary
                    opacity: 0.55
                    font.family: Appearance.clockFamily
                    font.pixelSize: 132
                    font.weight: Appearance.font.weightMedium
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
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

            // ===== password =====
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Appearance.space.s

                Rectangle {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 380
                    height: 60
                    radius: height / 2
                    color: Colors.surfaceContainerHigh
                    border.width: 2
                    border.color: root.errorText !== "" ? Colors.error
                                  : pwInput.activeFocus ? Colors.primary : "transparent"
                    Behavior on border.color { ColorAnimation { duration: Motion.durShort } }

                    transform: Translate { id: shakeT }
                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: shakeT; property: "x"; to: 11; duration: 45 }
                        NumberAnimation { target: shakeT; property: "x"; to: -11; duration: 45 }
                        NumberAnimation { target: shakeT; property: "x"; to: 6; duration: 45 }
                        NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 45 }
                    }

                    // The real input — invisible, it only collects keystrokes.
                    TextInput {
                        id: pwInput
                        anchors.fill: parent
                        opacity: 0
                        echoMode: TextInput.Password
                        selectByMouse: false
                        enabled: !root.busy
                        activeFocusOnPress: true
                        onAccepted: root.submit()
                        onTextChanged: if (root.errorText !== "") root.errorText = ""
                    }

                    // Idle hint — a lock that opens the moment anything is typed.
                    MIcon {
                        anchors.centerIn: parent
                        visible: pwInput.text.length === 0 && !root.busy
                        name: "lock"
                        size: 22
                        fill: 1
                        color: Colors.on.surfaceVariant
                        opacity: 0.7
                    }

                    // Masked characters, as Material shapes.
                    Row {
                        id: shapesRow
                        anchors.centerIn: parent
                        spacing: 10
                        visible: pwInput.text.length > 0

                        readonly property var kinds: [
                            "clover", "diamond", "burst", "pill", "pentagon",
                            "flower", "triangle", "circle", "square"
                        ]
                        readonly property int slots: 12
                        readonly property int filled: Math.min(pwInput.text.length, slots)

                        // Fixed-size model on purpose. Assigning a new number to
                        // `model` swaps the whole delegate model out, so every
                        // shape would be rebuilt — and re-animated — on each
                        // keystroke. With a constant count the delegates are
                        // built once and only the slot that just lit up plays.
                        Repeater {
                            model: shapesRow.slots
                            delegate: Item {
                                id: cell
                                required property int index
                                readonly property bool shown: index < shapesRow.filled

                                visible: shown          // Row skips hidden children
                                width: 18
                                height: 18

                                onShownChanged: if (shown) {
                                    glyph.scale = 0
                                    glyph.opacity = 0
                                    glyph.color = Colors.primary
                                    appear.restart()
                                }

                                MShape {
                                    id: glyph
                                    anchors.centerIn: parent
                                    size: 18
                                    shape: shapesRow.kinds[cell.index % shapesRow.kinds.length]
                                    // a deterministic tilt per slot, so a row of
                                    // them reads as hand-placed rather than stamped
                                    rotation_: (cell.index * 47) % 360
                                    color: Colors.primary
                                    scale: 0
                                    opacity: 0

                                    ParallelAnimation {
                                        id: appear
                                        NumberAnimation {
                                            target: glyph; property: "opacity"
                                            to: 1; duration: 90
                                        }
                                        // the overshoot is the Pixel feel
                                        NumberAnimation {
                                            target: glyph; property: "scale"
                                            to: 1; duration: 340
                                            easing.type: Easing.OutBack
                                            easing.overshoot: 2.6
                                        }
                                        // flashes in the accent, then settles
                                        ColorAnimation {
                                            target: glyph; property: "color"
                                            from: Colors.primary
                                            to: Colors.on.surfaceVariant
                                            duration: 900
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Checking — the shapes pulse rather than a spinner appearing.
                    SequentialAnimation on opacity {
                        running: root.busy
                        loops: Animation.Infinite
                        alwaysRunToEnd: true
                        NumberAnimation { to: 0.55; duration: 420; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 420; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 16
                    text: root.errorText
                    color: Colors.error
                    opacity: root.errorText !== "" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.labelSmall
                    font.weight: Appearance.font.weightMedium
                }
            }

            // ===== session actions =====
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Appearance.space.m

                LockAction {
                    glyph: "bedtime"
                    onActivated: root.run(["systemctl", "suspend"])
                }
                LockAction {
                    glyph: "logout"
                    onActivated: root.run(["niri", "msg", "action", "quit", "-s"])
                }
                LockAction {
                    glyph: "restart_alt"
                    onActivated: root.run(["systemctl", "reboot"])
                }
                LockAction {
                    glyph: "power_settings_new"
                    onActivated: root.run(["systemctl", "poweroff"])
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/config"
import "root:/components"
import "root:/services"

// Month calendar, opened by clicking the bar date. Monday-first grid, today
// pilled in the primary colour, month arrows + jump-to-today.
PanelWindow {
    id: root
    visible: Bus.calendarOpen
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-calendar"
    WlrLayershell.keyboardFocus: Bus.calendarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    property date view: new Date()
    property date now: new Date()
    property var sel: null   // { y, m, d } — the tapped day, outlined

    onVisibleChanged: if (visible) { view = new Date(); now = new Date(); sel = null }

    Timer {
        running: root.visible
        interval: 30000
        repeat: true
        onTriggered: root.now = new Date()
    }

    readonly property int vYear: view.getFullYear()
    readonly property int vMonth: view.getMonth()

    function shiftMonth(d) {
        const nd = new Date(view)
        nd.setDate(1)
        nd.setMonth(nd.getMonth() + d)
        view = nd
    }

    // Leading blanks (Mon-first) + day numbers + trailing blanks to fill weeks.
    readonly property var cells: {
        const first = new Date(vYear, vMonth, 1)
        const lead = (first.getDay() + 6) % 7
        const count = new Date(vYear, vMonth + 1, 0).getDate()
        const out = []
        for (let i = 0; i < lead; i++) out.push(0)
        for (let d = 1; d <= count; d++) out.push(d)
        while (out.length % 7 !== 0) out.push(0)
        return out
    }

    Item {
        anchors.fill: parent
        focus: Bus.calendarOpen
        Keys.onEscapePressed: Bus.calendarOpen = false

        MouseArea { anchors.fill: parent; onClicked: Bus.calendarOpen = false }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Bus.calendarOpen
                ? Appearance.barInsetTop
                : -(height + 24)
            width: 320
            height: col.implicitHeight + Appearance.space.l * 2
            radius: Appearance.radius.xl
            color: Colors.surfaceContainerHigh

            opacity: Bus.calendarOpen ? 1 : 0
            Behavior on anchors.topMargin {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            MouseArea { anchors.fill: parent } // swallow clicks inside the card

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.space.l
                spacing: Appearance.space.m

                // ---- header ----------------------------------------
                Item {
                    width: parent.width
                    height: 34

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDate(new Date(root.vYear, root.vMonth, 1), "MMMM yyyy")
                        color: Colors.on.surface
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.titleMedium
                        font.weight: Appearance.font.weightMedium
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.space.xs

                        MButton { icon: "chevron_left"; iconSize: 20; onClicked: root.shiftMonth(-1) }
                        MButton { icon: "today"; iconSize: 17; onClicked: root.view = new Date() }
                        MButton { icon: "chevron_right"; iconSize: 20; onClicked: root.shiftMonth(1) }
                    }
                }

                // ---- weekday labels -----------------------------
                Row {
                    width: parent.width
                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]
                        delegate: Item {
                            required property var modelData
                            width: col.width / 7
                            height: 22
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: Colors.on.surfaceVariant
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.labelSmall
                                font.weight: Appearance.font.weightMedium
                            }
                        }
                    }
                }

                // ---- day grid --------------------------------
                Grid {
                    width: parent.width
                    columns: 7

                    Repeater {
                        model: root.cells
                        delegate: Item {
                            id: cell
                            required property var modelData
                            width: col.width / 7
                            height: col.width / 7

                            readonly property bool isToday: modelData > 0
                                && root.vYear === root.now.getFullYear()
                                && root.vMonth === root.now.getMonth()
                                && modelData === root.now.getDate()
                            readonly property bool isSel: modelData > 0 && root.sel
                                && root.sel.y === root.vYear
                                && root.sel.m === root.vMonth
                                && root.sel.d === modelData

                            // hover wash
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 8
                                height: width
                                radius: width / 2
                                visible: !cell.isToday && dayMa.containsMouse
                                color: Colors.on.surface
                                opacity: Appearance.stateHover
                            }
                            // today fill / selected outline
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 8
                                height: width
                                radius: width / 2
                                color: cell.isToday ? Colors.primary : "transparent"
                                border.width: (cell.isSel && !cell.isToday) ? 1.5 : 0
                                border.color: Colors.primary
                                Behavior on border.width { NumberAnimation { duration: Motion.durShort } }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: modelData > 0
                                text: modelData > 0 ? modelData : ""
                                color: cell.isToday ? Colors.on.primary
                                       : cell.isSel ? Colors.primary : Colors.on.surface
                                font.family: Appearance.clockFamily
                                font.pixelSize: Appearance.font.labelMedium
                                font.weight: (cell.isToday || cell.isSel)
                                    ? Appearance.font.weightBold
                                    : Appearance.font.weightRegular
                            }

                            MouseArea {
                                id: dayMa
                                anchors.fill: parent
                                enabled: modelData > 0
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sel = cell.isSel
                                    ? null
                                    : ({ y: root.vYear, m: root.vMonth, d: cell.modelData })
                            }
                        }
                    }
                }
            }
        }
    }
}

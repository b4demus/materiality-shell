import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"

// The clock for a vertical bar: hours stacked over minutes, because "HH:mm"
// laid out horizontally does not fit in a column a few dozen pixels wide.
// Tapping it opens the same alarm/timer popup as the wide clock; the small
// day-of-month dot below opens the calendar.
Item {
    id: root

    implicitWidth: Math.max(28, Appearance.barIconSize + Appearance.space.m)
    implicitHeight: col.implicitHeight + Appearance.space.s

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.s
        color: Bus.timePopupOpen ? Colors.primary : Colors.barOnSurface
        opacity: Bus.timePopupOpen ? 0.16
                 : ma.pressed ? Appearance.statePress
                 : ma.containsMouse ? Appearance.stateHover : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        Behavior on color { ColorAnimation { duration: Motion.durShort } }
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: -2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH")
            color: Colors.barOnSurface
            font.family: Appearance.clockFamily
            font.pixelSize: Appearance.barFontSize
            font.weight: Appearance.font.weightMedium
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            color: Colors.barOnSurfaceVariant
            font.family: Appearance.clockFamily
            font.pixelSize: Appearance.barFontSize
            font.weight: Appearance.font.weightMedium
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            Bus.mediaPopupOpen = false
            if (mouse.button === Qt.RightButton) {
                Bus.timePopupOpen = false
                Bus.calendarOpen = !Bus.calendarOpen
            } else {
                Bus.calendarOpen = false
                Bus.timePopupOpen = !Bus.timePopupOpen
            }
        }
    }
}

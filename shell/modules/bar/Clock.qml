import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"

// Bar clock. The time opens the alarm / timer popup, the date opens the
// calendar. Each half gets its own rounded hover / active state layer.
Row {
    id: root
    spacing: Appearance.space.xs

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- time -> alarm / timer -------------------------------------------
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: timeLabel.implicitWidth + Appearance.space.s * 2
        height: 24

        Rectangle {
            anchors.fill: parent
            radius: Appearance.radius.full
            color: Bus.timePopupOpen ? Colors.primary : Colors.barOnSurface
            opacity: Bus.timePopupOpen ? 0.16
                     : timeMa.pressed ? Appearance.statePress
                     : timeMa.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
            Behavior on color { ColorAnimation { duration: Motion.durShort } }
        }

        Text {
            id: timeLabel
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Colors.barOnSurface
            font.family: Appearance.clockFamily
            font.pixelSize: Appearance.font.labelLarge
            font.weight: Appearance.font.weightMedium
        }

        MouseArea {
            id: timeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Bus.calendarOpen = false
                Bus.mediaPopupOpen = false
                Bus.timePopupOpen = !Bus.timePopupOpen
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 3; height: 3; radius: 2
        color: Colors.barOnSurfaceVariant
        opacity: 0.6
    }

    // ---- date -> calendar ---------------------------------------------
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: dateLabel.implicitWidth + Appearance.space.s * 2
        height: 24

        Rectangle {
            anchors.fill: parent
            radius: Appearance.radius.full
            color: Bus.calendarOpen ? Colors.primary : Colors.barOnSurface
            opacity: Bus.calendarOpen ? 0.16
                     : dateMa.pressed ? Appearance.statePress
                     : dateMa.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
            Behavior on color { ColorAnimation { duration: Motion.durShort } }
        }

        Text {
            id: dateLabel
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Colors.barOnSurfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.labelMedium
        }

        MouseArea {
            id: dateMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Bus.timePopupOpen = false
                Bus.mediaPopupOpen = false
                Bus.calendarOpen = !Bus.calendarOpen
            }
        }
    }
}

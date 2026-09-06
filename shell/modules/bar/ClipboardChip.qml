import QtQuick
import "root:/config"
import "root:/components"
import "root:/services"

// Bar chip that opens the clipboard-history popup. Sits just left of the clock.
Item {
    id: root
    implicitWidth: 28
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.full
        color: Bus.clipboardOpen ? Colors.primary : Colors.barOnSurface
        opacity: Bus.clipboardOpen ? 0.16
                 : ma.pressed ? Appearance.statePress
                 : ma.containsMouse ? Appearance.stateHover : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        Behavior on color { ColorAnimation { duration: Motion.durShort } }
    }

    MIcon {
        anchors.centerIn: parent
        name: "content_paste"
        size: 16
        color: Bus.clipboardOpen ? Colors.primary : Colors.barOnSurfaceVariant
    }

    // little count badge
    Rectangle {
        visible: Clipboard.entries.length > 0 && !Bus.clipboardOpen
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 1
        anchors.topMargin: 1
        width: 6; height: 6; radius: 3
        color: Colors.primary
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Bus.timePopupOpen = false
            Bus.calendarOpen = false
            Bus.mediaPopupOpen = false
            Bus.clipboardOpen = !Bus.clipboardOpen
        }
    }
}

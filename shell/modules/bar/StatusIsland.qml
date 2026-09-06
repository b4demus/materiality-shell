import QtQuick
import "root:/config"
import "root:/components"
import "root:/services"

// Android-style quick-status cluster: network + bluetooth + volume + battery.
// Click -> quick settings. Scroll -> volume. Plain on the solid bar, with just a
// subtle rounded hover highlight.
Item {
    id: root

    // The cluster runs along the bar: a row on a horizontal bar, a column on a
    // vertical one. Without this the four icons overflow a narrow bar.
    readonly property bool vertical: Appearance.barVertical

    implicitWidth: contentRow.implicitWidth + (vertical ? Appearance.space.xs
                                                        : Appearance.space.m) * 2
    implicitHeight: contentRow.implicitHeight + (vertical ? Appearance.space.m
                                                          : 0) * 2

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.full
        color: Bus.controlCenterOpen ? Colors.primary
               : (islandMa.containsMouse || islandMa.pressed) ? Colors.barOnSurface : "transparent"
        opacity: Bus.controlCenterOpen ? 0.18
                 : islandMa.pressed ? Appearance.statePress
                 : islandMa.containsMouse ? Appearance.stateHover : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
        Behavior on color { ColorAnimation { duration: Motion.durShort } }
    }

    Grid {
        id: contentRow
        anchors.centerIn: parent
        rows: root.vertical ? 0 : 1
        columns: root.vertical ? 1 : 0
        rowSpacing: Appearance.space.s
        columnSpacing: Appearance.space.m
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        MIcon {
            name: Net.icon
            size: 17
            color: Net.online ? Colors.barOnSurface : Colors.barOnSurfaceVariant
        }

        MIcon {
            visible: Bt.available
            name: Bt.icon
            size: 17
            fill: Bt.hasConnection ? 1 : 0
            color: Bt.enabled ? Colors.barOnSurface : Colors.barOnSurfaceVariant
        }

        MIcon {
            name: Audio.muted || Audio.volume <= 0 ? "volume_off"
                  : Audio.volume < 0.34 ? "volume_mute"
                  : Audio.volume < 0.67 ? "volume_down" : "volume_up"
            size: 17
            color: Audio.muted ? Colors.error : Colors.barOnSurface
        }

        Row {
            visible: Bat.present
            spacing: Appearance.space.xs

            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: Bat.icon
                size: 17
                fill: 1
                color: Bat.critical ? Colors.error
                       : Bat.charging ? Colors.primary : Colors.barOnSurface
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.vertical
                text: Math.round(Bat.percent) + "%"
                color: Colors.barOnSurfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelSmall
                font.weight: Appearance.font.weightMedium
            }
        }
    }

    MouseArea {
        id: islandMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Audio.toggleMute()
            else Bus.controlCenterOpen = !Bus.controlCenterOpen
        }
        onWheel: w => Audio.changeVolume(w.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}

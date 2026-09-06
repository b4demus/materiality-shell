import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "root:/config"
import "root:/components"
import "root:/services"

// Now-playing chip. Plain inline controls on the solid bar. Visible only when
// some MPRIS player has a track.
Row {
    id: root
    spacing: Appearance.space.xs

    readonly property var player: {
        const list = Mpris.players ? Mpris.players.values : []
        let playing = null
        for (const p of list) {
            if (!p) continue
            if (p.playbackState === MprisPlaybackState.Playing) return p
            if (!playing) playing = p
        }
        return playing
    }
    readonly property string title: player && player.trackTitle ? player.trackTitle : ""
    readonly property bool isPlaying: player && player.playbackState === MprisPlaybackState.Playing

    visible: title !== ""
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

    // Click anywhere on the chip that isn't a transport button -> toggle the
    // media popup. The MButtons below grab their own taps.
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            Bus.timePopupOpen = false
            Bus.calendarOpen = false
            Bus.mediaPopupOpen = !Bus.mediaPopupOpen
        }
    }

    MEqualizer {
        anchors.verticalCenter: parent.verticalCenter
        active: root.isPlaying
        barColor: Colors.primary
    }

    MButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: root.isPlaying ? "pause" : "play_arrow"
        iconSize: 20
        iconFill: 1
        vpad: 5
        minSize: 28
        fg: Colors.primary
        enabled: root.player && root.player.canTogglePlaying
        onClicked: root.player && root.player.togglePlaying()
    }

    MButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: "skip_next"
        iconSize: 18
        vpad: 5
        minSize: 28
        fg: Colors.barOnSurfaceVariant
        enabled: root.player && root.player.canGoNext
        onClicked: root.player && root.player.next()
    }

    // Track name — its own hover/active state layer, like the clock halves.
    // Click opens the media popup.
    Item {
        id: titleZone
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(titleLabel.implicitWidth + Appearance.space.s * 2, 208)
        height: 24

        Rectangle {
            anchors.fill: parent
            radius: Appearance.radius.full
            color: Bus.mediaPopupOpen ? Colors.primary : Colors.barOnSurface
            opacity: Bus.mediaPopupOpen ? 0.16
                     : titleMa.pressed ? Appearance.statePress
                     : titleMa.containsMouse ? Appearance.stateHover : 0
            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
            Behavior on color { ColorAnimation { duration: Motion.durShort } }
        }

        Text {
            id: titleLabel
            anchors.centerIn: parent
            width: parent.width - Appearance.space.s * 2
            elide: Text.ElideRight
            text: {
                const a = root.player && root.player.trackArtist ? root.player.trackArtist : ""
                return a ? a + " — " + root.title : root.title
            }
            color: Colors.barOnSurfaceVariant
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.font.labelMedium
            font.weight: Appearance.font.weightMedium
        }

        MouseArea {
            id: titleMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Bus.timePopupOpen = false
                Bus.calendarOpen = false
                Bus.mediaPopupOpen = !Bus.mediaPopupOpen
            }
        }
    }
}

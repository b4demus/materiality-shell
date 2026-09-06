import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "root:/config"
import "root:/components"
import "root:/services"

// Now-playing popup, opened by clicking the bar media chip. Cover art, a
// Material Expressive progress bar (real seek when the player reports a length,
// an indeterminate sweep + local elapsed estimate otherwise) and transport.
PanelWindow {
    id: root
    visible: Bus.mediaPopupOpen
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-mediapopup"
    WlrLayershell.keyboardFocus: Bus.mediaPopupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    // Same "best current player" pick as the chip.
    readonly property var player: {
        const list = Mpris.players ? Mpris.players.values : []
        let fallback = null
        for (const p of list) {
            if (!p) continue
            if (p.playbackState === MprisPlaybackState.Playing) return p
            if (!fallback) fallback = p
        }
        return fallback
    }
    readonly property bool hasTrack: player && player.trackTitle && player.trackTitle !== ""
    readonly property bool isPlaying: player && player.playbackState === MprisPlaybackState.Playing

    readonly property real realPos: player && player.positionSupported ? player.position : 0
    readonly property real realLen: player && player.lengthSupported ? player.length : 0
    // A player that gives us a real length -> a real, seekable progress bar.
    // Firefox reports neither length nor a moving position, so fall back to a
    // locally-counted elapsed and an indeterminate bar.
    readonly property bool determinate: realLen > 1

    property real localElapsed: 0
    readonly property string trackKey: player
        ? ((player.trackTitle || "") + " " + (player.trackArtist || ""))
        : ""
    onTrackKeyChanged: localElapsed = 0

    readonly property real shownPos: determinate ? realPos : localElapsed
    readonly property real shownLen: realLen

    // Local elapsed — runs whenever playback is going, so it stays roughly right
    // even while the popup is closed.
    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying && root.hasTrack
        onTriggered: root.localElapsed += 1
    }
    // Re-fetch the real position from the player — only while the popup is up.
    Timer {
        interval: 1000
        repeat: true
        running: Bus.mediaPopupOpen && root.isPlaying
                 && root.player && root.player.positionSupported
        onTriggered: if (root.player) root.player.positionChanged()
    }

    // Cover art. Prefer the player's own MPRIS art; if it exports none (Firefox
    // doesn't), derive a YouTube thumbnail from the track URL in the metadata.
    readonly property string artUrl: {
        const p = root.player
        if (!p) return ""
        if (p.trackArtUrl && ("" + p.trackArtUrl).length > 0) return "" + p.trackArtUrl
        const md = p.metadata || ({})
        const u = "" + (md["xesam:url"] || "")
        const m = u.match(/(?:v=|youtu\.be\/|\/embed\/|\/shorts\/|\/watch\?.*?v=)([\w-]{11})/)
        if (m) return "https://i.ytimg.com/vi/" + m[1] + "/mqdefault.jpg"
        return ""
    }

    function fmt(t) {
        if (!t || t < 0 || !isFinite(t)) return "0:00"
        t = Math.floor(t)
        const h = Math.floor(t / 3600)
        const m = Math.floor((t % 3600) / 60)
        const s = t % 60
        const mm = h > 0 ? ("0" + m).slice(-2) : ("" + m)
        return (h > 0 ? h + ":" : "") + mm + ":" + ("0" + s).slice(-2)
    }

    Item {
        anchors.fill: parent
        focus: Bus.mediaPopupOpen
        Keys.onEscapePressed: Bus.mediaPopupOpen = false

        MouseArea { anchors.fill: parent; onClicked: Bus.mediaPopupOpen = false }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Bus.mediaPopupOpen
                ? Appearance.barInsetTop
                : -(height + 24)
            width: 380
            height: content.implicitHeight + Appearance.space.l * 2
            radius: Appearance.radius.xl
            color: Colors.surfaceContainerHigh

            opacity: Bus.mediaPopupOpen ? 1 : 0
            Behavior on anchors.topMargin {
                SpringAnimation {
                    spring: Motion.spatial.spring; damping: Motion.spatial.damping
                    mass: Motion.spatial.mass; epsilon: Motion.spatial.epsilon
                }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

            MouseArea { anchors.fill: parent } // swallow clicks inside the card

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.space.l
                spacing: Appearance.space.m

                // ---- track header --------------------------------------
                // Hover/press highlight like the rest of the UI; click raises the
                // player's own window when it supports it.
                Rectangle {
                    id: header
                    width: parent.width
                    // fixed — the art is always 56, so this never has to wait on
                    // the row's own implicit size (a NaN there once hid the art)
                    height: 56 + Appearance.space.s * 2
                    radius: Appearance.radius.m
                    color: "transparent"

                    readonly property int artSize: 56
                    readonly property int eqSize: 24

                    Row {
                        id: headerRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Appearance.space.s
                        anchors.rightMargin: Appearance.space.s
                        spacing: Appearance.space.m

                        Rectangle {
                            id: art
                            width: header.artSize; height: header.artSize
                            radius: Appearance.radius.m
                            color: Colors.surfaceContainerHighest
                            clip: true

                            Image {
                                id: artImg
                                anchors.fill: parent
                                source: root.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: true
                                sourceSize.width: 160
                                sourceSize.height: 160
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }
                            }
                            MIcon {
                                anchors.centerIn: parent
                                visible: artImg.status !== Image.Ready
                                name: "music_note"
                                size: 26
                                color: Colors.on.surfaceVariant
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, headerRow.width - header.artSize
                                            - header.eqSize - Appearance.space.m * 2)
                            spacing: 2

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: root.player && root.player.trackTitle
                                    ? root.player.trackTitle : "Nothing playing"
                                color: Colors.on.surface
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.bodyLarge
                                font.weight: Appearance.font.weightMedium
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                visible: text !== ""
                                text: root.player && root.player.trackArtist ? root.player.trackArtist : ""
                                color: Colors.on.surfaceVariant
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.font.labelMedium
                            }
                        }

                        MEqualizer {
                            id: eq
                            anchors.verticalCenter: parent.verticalCenter
                            width: header.eqSize
                            active: root.isPlaying
                            barColor: Colors.primary
                            bars: 5
                            maxHeight: 18
                        }
                    }

                    MouseArea {
                        id: headerMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (root.player && root.player.canRaise)
                                     ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (root.player && root.player.canRaise) root.player.raise()
                    }

                    // M3 state layer, on top — hover/press highlight like every
                    // other interactive element.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.on.surface
                        opacity: headerMa.pressed ? Appearance.statePress
                                 : headerMa.containsMouse ? Appearance.stateHover : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                    }
                }

                // ---- progress ---------------------------------------
                Item {
                    width: parent.width
                    height: 20

                    // real, seekable position — Material Expressive wavy track
                    MWaveSlider {
                        anchors.fill: parent
                        visible: root.determinate
                        playing: root.isPlaying
                        interactive: root.player && root.player.canSeek
                        value: root.determinate
                            ? Math.max(0, Math.min(1, root.shownPos / root.shownLen))
                            : 0
                        onMoved: v => {
                            if (root.player && root.player.canSeek && root.shownLen > 0)
                                root.player.position = v * root.shownLen
                        }
                    }

                    // indeterminate sweep when the player gives us no length
                    Rectangle {
                        id: indet
                        anchors.fill: parent
                        visible: !root.determinate
                        radius: height / 2
                        color: Colors.secondaryContainer

                        Rectangle {
                            id: seg
                            width: parent.width * 0.34
                            height: parent.height
                            radius: height / 2
                            color: Colors.primary

                            SequentialAnimation on x {
                                running: indet.visible && root.isPlaying
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: 0; to: indet.width - seg.width
                                    duration: 1500; easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    from: indet.width - seg.width; to: 0
                                    duration: 1500; easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: elapsed.implicitHeight

                    Text {
                        id: elapsed
                        anchors.left: parent.left
                        text: root.fmt(root.shownPos)
                        color: Colors.on.surfaceVariant
                        font.family: Appearance.clockFamily
                        font.pixelSize: Appearance.font.labelSmall
                    }
                    Text {
                        anchors.right: parent.right
                        text: root.determinate ? root.fmt(root.shownLen) : "live"
                        color: Colors.on.surfaceVariant
                        font.family: Appearance.clockFamily
                        font.pixelSize: Appearance.font.labelSmall
                    }
                }

                // ---- transport --------------------------------------
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Appearance.space.l

                    MButton {
                        icon: "skip_previous"
                        iconSize: 22
                        iconFill: 1
                        fg: Colors.on.surfaceVariant
                        enabled: root.player && root.player.canGoPrevious
                        onClicked: if (root.player) root.player.previous()
                    }
                    MButton {
                        icon: root.isPlaying ? "pause" : "play_arrow"
                        iconSize: 26
                        iconFill: 1
                        bg: Colors.primaryContainer
                        fg: Colors.on.primaryContainer
                        hpad: Appearance.space.l
                        enabled: root.player && root.player.canTogglePlaying
                        onClicked: if (root.player) root.player.togglePlaying()
                    }
                    MButton {
                        icon: "skip_next"
                        iconSize: 22
                        iconFill: 1
                        fg: Colors.on.surfaceVariant
                        enabled: root.player && root.player.canGoNext
                        onClicked: if (root.player) root.player.next()
                    }
                }
            }
        }
    }
}

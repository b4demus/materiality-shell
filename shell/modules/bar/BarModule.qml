import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "root:/config"
import "root:/components"
import "root:/services"

// Turns a module id from the settings store into the widget that renders it.
// The bar itself only knows the ids; everything about what a module *is* lives
// here, so adding one is a single entry in this switch plus a Component.
Loader {
    id: root

    property string moduleId: ""
    property var bar: null
    property string outputName: ""

    // Modules that need polling only subscribe while they are on the bar.
    readonly property bool needsSysInfo: ["cpu", "ram", "temperature", "network", "sysmon"]
                                         .indexOf(moduleId) >= 0
    Component.onCompleted: if (needsSysInfo) SysInfo.subscribe()
    Component.onDestruction: if (needsSysInfo) SysInfo.unsubscribe()

    // Set by the owning layout: a Row centres its children vertically, a Column
    // horizontally. Declaring both would make whichever layout isn't in use
    // complain about a conflicting anchor.
    property bool inColumn: false

    anchors.verticalCenter: inColumn || !parent ? undefined : parent.verticalCenter
    anchors.horizontalCenter: inColumn && parent ? parent.horizontalCenter : undefined

    // A vertical bar is only tens of pixels wide, so the modules that are
    // inherently wide (a window title, a kaomoji, "HH:mm  ·  Sat 5 Sep") get a
    // compact stand-in rather than overflowing across the desktop.
    readonly property bool vertical: Appearance.barVertical

    sourceComponent: {
        switch (moduleId) {
        case "workspaces":   return workspacesC
        case "windowTitle":  return vertical ? titleIconC : titleC
        case "clock":        return vertical ? clockVerticalC : clockC
        case "date":         return dateC
        case "media":        return vertical ? mediaIconC : mediaC
        case "clipboard":    return clipboardC
        case "kaomoji":      return vertical ? null : kaomojiC
        case "tray":         return trayC
        case "statusIsland": return islandC
        case "wifi":         return wifiC
        case "bluetooth":    return btC
        case "volume":       return volumeC
        case "microphone":   return micC
        case "battery":      return batteryC
        case "cpu":          return cpuC
        case "ram":          return ramC
        case "temperature":  return tempC
        case "network":      return netSpeedC
        case "sysmon":       return vertical ? null : sysmonC
        case "vpn":          return vpnC
        case "notifications": return notifC
        case "power":        return powerC
        }
        return null
    }

    // ---- existing rich modules --------------------------------------------
    Component { id: workspacesC; Workspaces { outputName: root.outputName } }
    Component { id: clockVerticalC; VerticalClock {} }

    // Just the focused app's marker — the title itself has nowhere to go.
    Component {
        id: titleIconC
        BarChip {
            visible: Niri.focusedAppId !== "" || Niri.focusedTitle !== ""
            icon: "widgets"
            fg: Colors.primary
        }
    }

    // Play/pause only; the popup still carries the track details.
    Component {
        id: mediaIconC
        BarChip {
            id: mediaChip

            // Same pick as the wide chip: whatever is playing, else the first
            // player that has a track at all.
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
            readonly property bool playing: player
                && player.playbackState === MprisPlaybackState.Playing

            visible: player && player.trackTitle
            icon: playing ? "pause" : "play_arrow"
            iconFill: 1
            fg: Colors.primary
            onClicked: if (player && player.canTogglePlaying) player.togglePlaying()
            onRightClicked: {
                Bus.timePopupOpen = false
                Bus.calendarOpen = false
                Bus.mediaPopupOpen = !Bus.mediaPopupOpen
            }
        }
    }
    Component { id: titleC;      FocusedWindow { maxWidth: 320 } }
    Component { id: clockC;      Clock {} }
    Component { id: mediaC;      MediaChip {} }
    Component { id: clipboardC;  ClipboardChip {} }
    Component { id: kaomojiC;    KaomojiChip {} }
    Component { id: trayC;       SysTray { bar: root.bar } }
    Component { id: islandC;     StatusIsland {} }

    // ---- small status modules ------------------------------------------------
    Component {
        id: dateC
        BarChip {
            // Its own clock — TimeTools has no date property, so this chip used
            // to format `undefined` and render a blank label.
            SystemClock { id: dateClock; precision: SystemClock.Minutes }
            icon: "calendar_month"
            label: Qt.formatDate(dateClock.date, "ddd d MMM")
            onClicked: { Bus.timePopupOpen = false; Bus.calendarOpen = !Bus.calendarOpen }
        }
    }

    Component {
        id: wifiC
        BarChip {
            icon: Net.icon
            fg: Net.online ? Colors.barOnSurface : Colors.barOnSurfaceVariant
            onClicked: Bus.openSettings("wifi")
            onRightClicked: Net.toggleWifi()
        }
    }

    Component {
        id: btC
        BarChip {
            visible: Bt.available
            icon: Bt.icon
            iconFill: Bt.hasConnection ? 1 : 0
            fg: Bt.enabled ? Colors.barOnSurface : Colors.barOnSurfaceVariant
            onClicked: Bus.openSettings("bluetooth")
            onRightClicked: Bt.toggle()
        }
    }

    Component {
        id: volumeC
        BarChip {
            icon: Audio.icon
            label: Audio.muted ? "" : Math.round(Audio.volume * 100) + "%"
            fg: Audio.muted ? Colors.error : Colors.barOnSurface
            onClicked: Audio.toggleMute()
            onRightClicked: Bus.openSettings("audio")
            onWheel: d => Audio.changeVolume(d > 0 ? 0.05 : -0.05)
        }
    }

    Component {
        id: micC
        BarChip {
            visible: Audio.micReady
            icon: Audio.micMuted ? "mic_off" : "mic"
            fg: Audio.micMuted ? Colors.error : Colors.barOnSurface
            onClicked: Audio.toggleMicMute()
        }
    }

    Component {
        id: batteryC
        BarChip {
            visible: Bat.present
            icon: Bat.icon
            iconFill: 1
            label: Math.round(Bat.percent) + "%"
            fg: Bat.critical ? Colors.error
                : Bat.charging ? Colors.primary : Colors.barOnSurface
            onClicked: Bus.openSettings("power")
        }
    }

    Component {
        id: cpuC
        BarChip {
            icon: "memory"
            label: Math.round(SysInfo.cpu * 100) + "%"
            fg: SysInfo.cpu > 0.85 ? Colors.error : Colors.barOnSurface
            onClicked: Bus.openSettings("about")
        }
    }

    Component {
        id: ramC
        BarChip {
            icon: "memory_alt"
            label: SysInfo.memUsedGb.toFixed(1) + " G"
            fg: SysInfo.memory > 0.9 ? Colors.error : Colors.barOnSurface
        }
    }

    Component {
        id: tempC
        BarChip {
            visible: SysInfo.temperature > 0
            icon: "device_thermostat"
            label: Math.round(SysInfo.temperature) + "°"
            fg: SysInfo.temperature > 80 ? Colors.error : Colors.barOnSurface
        }
    }

    Component {
        id: netSpeedC
        BarChip {
            icon: "swap_vert"
            label: SysInfo.humanRate(SysInfo.rxRate)
            fg: Colors.barOnSurfaceVariant
            onClicked: Bus.openSettings("wifi")
        }
    }

    // Combined CPU / GPU / RAM readout — one chip. GPU folds away on machines
    // (VMs) that expose no utilisation counter.
    Component {
        id: sysmonC
        Item {
            id: sm
            implicitWidth: smRow.implicitWidth + Appearance.space.m
            implicitHeight: Math.max(20, Appearance.barIconSize + Appearance.space.xs)

            component Stat: Row {
                id: st
                property string glyph: ""
                property real frac: 0
                readonly property bool warn: frac > 0.9
                spacing: 2
                MIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: st.glyph
                    size: Appearance.barIconSize
                    color: st.warn ? Colors.error : Colors.barOnSurfaceVariant
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(st.frac * 100) + "%"
                    color: st.warn ? Colors.error : Colors.barOnSurface
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.barFontSize
                    font.weight: Appearance.font.weightMedium
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.radius.full
                color: Colors.barOnSurface
                opacity: sMa.pressed ? Appearance.statePress
                         : sMa.containsMouse ? Appearance.stateHover : 0
                Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
            }

            Row {
                id: smRow
                anchors.centerIn: parent
                spacing: Appearance.space.s

                Stat { glyph: "memory";          frac: SysInfo.cpu }
                Stat { glyph: "developer_board"; frac: SysInfo.gpu; visible: SysInfo.gpuAvailable }
                Stat { glyph: "memory_alt";      frac: SysInfo.memory }
            }

            MouseArea {
                id: sMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Bus.openSettings("about")
            }
        }
    }

    Component {
        id: vpnC
        BarChip {
            visible: Net.kind !== "disconnected"
            icon: "vpn_lock"
            fg: Colors.barOnSurfaceVariant
            onClicked: Bus.openSettings("wifi")
        }
    }

    Component {
        id: notifC
        BarChip {
            icon: Settings.val("notifications.dnd", false)
                  ? "notifications_off" : "notifications"
            active: Settings.val("notifications.dnd", false)
            fg: Colors.barOnSurface
            onClicked: Settings.toggle("notifications.dnd")
            onRightClicked: Bus.openSettings("notifications")
        }
    }

    Component {
        id: powerC
        BarChip {
            icon: "power_settings_new"
            fg: Colors.barOnSurface
            onClicked: Bus.openSettings("power")
        }
    }
}

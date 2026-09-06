import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/config"
import "root:/components"
import "root:/services"

// M3 Expressive app launcher. Toggled by:  qs -c expressive ipc call launcher toggle
PanelWindow {
    id: root
    visible: Bus.launcherOpen
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-launcher"
    WlrLayershell.keyboardFocus: Bus.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    property int selected: 0

    readonly property var apps: {
        const model = DesktopEntries.applications
        const all = !model ? [] : (model.values !== undefined ? model.values : model)
        return all.filter(a => a && !a.noDisplay)
    }

    function score(entry, q) {
        if (!q) return 1
        const name = (entry.name || "").toLowerCase()
        const gen = (entry.genericName || "").toLowerCase()
        const cmt = (entry.comment || "").toLowerCase()
        if (name.startsWith(q)) return 1000 - name.length
        if (name.includes(" " + q)) return 700
        if (name.includes(q)) return 500
        if (gen.includes(q)) return 200
        if (cmt.includes(q)) return 80
        // subsequence
        let i = 0
        for (const ch of name) if (ch === q[i]) i++
        return i === q.length ? 40 : -1
    }

    readonly property var results: {
        const q = search.text.trim().toLowerCase()
        return apps
            .map(a => ({ entry: a, s: score(a, q) }))
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s || (a.entry.name || "").localeCompare(b.entry.name || ""))
            .slice(0, 40)
            .map(x => x.entry)
    }

    onVisibleChanged: {
        if (visible) {
            search.text = ""
            selected = 0
            search.forceActiveFocus()
        }
    }
    onResultsChanged: selected = 0

    function launch(entry) {
        if (!entry) return
        entry.execute()
        Bus.launcherOpen = false
    }

    // scrim
    Rectangle {
        anchors.fill: parent
        color: Colors.scrim
        opacity: root.visible ? 0.45 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }
        MouseArea { anchors.fill: parent; onClicked: Bus.launcherOpen = false }
    }

    // card
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.16
        width: 560
        height: Math.min(parent.height * 0.6, header.height + list.contentHeight + Appearance.space.l * 2)
        radius: Appearance.radius.xl
        color: Colors.surfaceContainer
        clip: true

        scale: root.visible ? 1 : 0.94
        opacity: root.visible ? 1 : 0
        Behavior on scale {
            SpringAnimation {
                spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
                mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
            }
        }
        Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

        // search field
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Appearance.space.l
            height: 52
            radius: Appearance.radius.full
            color: Colors.surfaceContainerHighest

            MIcon {
                id: sIcon
                anchors.left: parent.left
                anchors.leftMargin: Appearance.space.l
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                size: 22
                color: Colors.on.surfaceVariant
            }

            TextField {
                id: search
                anchors.left: sIcon.right
                anchors.leftMargin: Appearance.space.m
                anchors.right: parent.right
                anchors.rightMargin: Appearance.space.l
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: "Search apps…"
                color: Colors.on.surface
                placeholderTextColor: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodyLarge
                background: null

                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) { Bus.launcherOpen = false; e.accepted = true }
                    else if (e.key === Qt.Key_Down) { root.selected = Math.min(root.results.length - 1, root.selected + 1); e.accepted = true }
                    else if (e.key === Qt.Key_Up) { root.selected = Math.max(0, root.selected - 1); e.accepted = true }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.launch(root.results[root.selected]); e.accepted = true }
                }
            }
        }

        // results
        ListView {
            id: list
            anchors.top: header.bottom
            anchors.topMargin: Appearance.space.s
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Appearance.space.s
            anchors.rightMargin: Appearance.space.s
            anchors.bottomMargin: Appearance.space.s
            clip: true
            model: root.results
            currentIndex: root.selected
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 48
                radius: Appearance.radius.m
                color: index === root.selected ? Colors.secondaryContainer : "transparent"

                Behavior on color { ColorAnimation { duration: Motion.durShort } }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.space.m
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.space.m
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.space.m

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 28
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 28 - Appearance.space.m
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: modelData.name || modelData.id
                            color: index === root.selected ? Colors.on.secondaryContainer : Colors.on.surface
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.bodyMedium
                            font.weight: Appearance.font.weightMedium
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            visible: text !== ""
                            text: modelData.genericName || modelData.comment || ""
                            color: Colors.on.surfaceVariant
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.font.labelSmall
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = index
                    onClicked: root.launch(modelData)
                }
            }
        }
    }
}

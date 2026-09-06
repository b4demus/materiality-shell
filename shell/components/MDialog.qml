import QtQuick
import "root:/config"

// Modal dialog.
//
// It has to cover the whole window, but settings pages hand their children to a
// Column inside a scrolling Flickable — where `anchors.fill` is rejected and a
// reparented-after-the-fact item silently fails to draw. So, exactly like
// MSelect's menu: the visible part (scrim + sheet) is built by a Loader whose
// component parents itself to the window root at creation. `root` itself stays a
// zero-size placeholder wherever it was declared, and the page's `body` content
// is stashed on it and moved into the sheet once.
Item {
    id: root

    property bool open: false
    property string title: ""
    property string message: ""
    property string icon: ""
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property bool destructive: false
    property bool confirmEnabled: true
    property real dialogWidth: 420

    default property alias body: bodyStash.data

    signal confirmed()
    signal cancelled()

    implicitWidth: 0
    implicitHeight: 0
    visible: false

    // Holds the page-supplied body content until the sheet exists.
    Item { id: bodyStash; visible: false }

    // Keep the sheet mapped a beat after close so the fade-out can play.
    property bool _shown: open
    onOpenChanged: {
        if (open) { closeTimer.stop(); _shown = true }
        else closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: Motion.durMedium + 120
        onTriggered: if (!root.open) root._shown = false
    }

    function _windowRoot() {
        let p = root
        while (p.parent) p = p.parent
        return p
    }

    Loader {
        active: true
        sourceComponent: sheetComponent
    }

    Component {
        id: sheetComponent

        Item {
            id: layer
            parent: root._windowRoot()
            anchors.fill: parent
            z: 9500
            visible: root._shown

            Component.onCompleted: {
                // Move the page's body content into the sheet, once.
                const kids = [].slice.call(bodyStash.children)
                for (const c of kids) c.parent = bodySlot
            }

            Rectangle {
                id: scrim
                anchors.fill: parent
                color: Colors.scrim
                opacity: root.open ? 0.45 : 0
                Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { root.open = false; root.cancelled() }
                }
            }

            Rectangle {
                id: sheet
                anchors.centerIn: parent
                width: Math.min(root.dialogWidth, layer.width - Appearance.space.xl * 2)
                height: col.implicitHeight + Appearance.space.xl * 2
                radius: Appearance.radius.xl
                color: Colors.surfaceContainerHigh

                opacity: root.open ? 1 : 0
                scale: root.open ? 1 : 0.9
                Behavior on opacity { NumberAnimation { duration: Motion.durMedium } }
                Behavior on scale {
                    SpringAnimation {
                        spring: Motion.expressive.spring; damping: Motion.expressive.damping
                        mass: Motion.expressive.mass; epsilon: Motion.expressive.epsilon
                    }
                }

                MouseArea { anchors.fill: parent }   // swallow clicks from the scrim

                Column {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Appearance.space.xl
                    spacing: Appearance.space.l

                    MIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.icon !== ""
                        name: root.icon
                        size: 28
                        color: root.destructive ? Colors.error : Colors.primary
                    }

                    Text {
                        width: parent.width
                        visible: root.title !== ""
                        text: root.title
                        horizontalAlignment: root.icon !== "" ? Text.AlignHCenter : Text.AlignLeft
                        wrapMode: Text.WordWrap
                        color: Colors.on.surface
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.headlineSmall
                    }

                    Text {
                        width: parent.width
                        visible: root.message !== ""
                        text: root.message
                        wrapMode: Text.WordWrap
                        horizontalAlignment: root.icon !== "" ? Text.AlignHCenter : Text.AlignLeft
                        color: Colors.on.surfaceVariant
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.bodyMedium
                    }

                    Column {
                        id: bodySlot
                        width: parent.width
                        spacing: Appearance.space.m
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: Appearance.space.s

                        MButton {
                            visible: root.cancelText !== ""
                            label: root.cancelText
                            fg: Colors.primary
                            hpad: Appearance.space.l
                            onClicked: { root.open = false; root.cancelled() }
                        }
                        MButton {
                            visible: root.confirmText !== ""
                            label: root.confirmText
                            bg: root.destructive ? Colors.error : Colors.primary
                            fg: root.destructive ? Colors.on.error : Colors.on.primary
                            hpad: Appearance.space.l
                            enabled: root.confirmEnabled
                            opacity: root.confirmEnabled ? 1 : 0.4
                            onClicked: if (root.confirmEnabled) { root.open = false; root.confirmed() }
                        }
                    }
                }
            }
        }
    }
}

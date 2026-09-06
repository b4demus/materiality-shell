import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "root:/config"
import "root:/components"
import "root:/services"

// ---------------------------------------------------------------------------
// Notification server plus the on-screen stack of M3 cards.
//
// Everything about behaviour — whether cards appear at all, where, for how long,
// and which applications are allowed through — is read from the settings store,
// so the Notifications page controls the real thing.
//
// Suppressed notifications are still *received*: they land in history rather
// than being dropped, which is what "do not disturb" should mean.
// ---------------------------------------------------------------------------
PanelWindow {
    id: root
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    readonly property string position: Settings.val("notifications.position", "top-right")
    readonly property bool atTop: position.indexOf("top") === 0
    readonly property bool atLeft: position.indexOf("left") >= 0
    readonly property bool atCentre: position.indexOf("center") >= 0
    readonly property bool enabled_: Settings.val("notifications.enabled", true)
    readonly property bool dnd: Settings.val("notifications.dnd", false)
    readonly property bool showing: enabled_ && !dnd && (!Bus.locked
        || Settings.val("notifications.showOnLockscreen", false))

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "expressive-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: root.atLeft || root.atCentre
        right: !root.atLeft || root.atCentre
    }
    implicitWidth: 400
    mask: Region { item: column }

    function allowed(n) {
        if (!n) return false
        const perApp = Settings.val("notifications.perApp", {})
        const key = n.appName || n.desktopEntry || "unknown"
        return perApp[key] !== false
    }

    // Remember every app that has ever sent one, so the settings page can list
    // them without the user having to type app names by hand.
    function remember(n) {
        const key = (n && (n.appName || n.desktopEntry)) || ""
        if (!key) return
        const perApp = Settings.val("notifications.perApp", {})
        if (perApp[key] === undefined) {
            const next = Object.assign({}, perApp)
            next[key] = true
            Settings.set("notifications.perApp", next)
        }
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        onNotification: n => {
            root.remember(n)
            n.tracked = root.showing && root.allowed(n)

            Notifs.add({
                appName: n.appName || "",
                summary: n.summary || "",
                body: n.body || "",
                time: Date.now()
            })
        }
    }

    Column {
        id: column
        width: 372
        spacing: Appearance.space.m

        // Sit clear of the bar on whichever edge it occupies.
        anchors.top: root.atTop ? parent.top : undefined
        anchors.bottom: root.atTop ? undefined : parent.bottom
        anchors.left: root.atLeft ? parent.left : undefined
        anchors.right: root.atLeft ? undefined : parent.right
        anchors.horizontalCenter: root.atCentre ? parent.horizontalCenter : undefined

        anchors.topMargin: Appearance.barInsetTop
        anchors.bottomMargin: Appearance.barInsetBottom
        anchors.leftMargin: Appearance.barInsetLeft
        anchors.rightMargin: Appearance.barInsetRight

        Repeater {
            model: server.trackedNotifications

            delegate: NotificationCard {
                required property var modelData
                width: column.width
                notif: modelData
            }
        }
    }
}

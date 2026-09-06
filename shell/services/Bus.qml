pragma Singleton

import QtQuick
import Quickshell

// Small shared state / event bus for cross-module signalling.
Singleton {
    id: root

    // Launcher visibility (toggled by IpcHandler in shell.qml, bound by Launcher.qml)
    property bool launcherOpen: false

    // Control center (phase 2) — wired now so the bar button already does something sane.
    property bool controlCenterOpen: false

    // Bar clock popups: click the time -> alarm / timer, click the date -> calendar.
    property bool timePopupOpen: false
    property bool calendarOpen: false

    // Media popup, toggled by clicking the bar media chip.
    property bool mediaPopupOpen: false

    // Clipboard-history popup, toggled by the bar clipboard chip.
    property bool clipboardOpen: false

    // Session lock screen.
    property bool locked: false

    // The settings application window.
    property bool settingsOpen: false
    // Page to show when it opens; lets other modules deep-link into a section.
    property string settingsPage: ""

    // Fires an OSD for manual testing: `qs -c expressive ipc call osd test`
    signal osdTest()

    function openSettings(page) {
        if (page) settingsPage = page
        settingsOpen = true
    }

    function closeAllOverlays() {
        launcherOpen = false
        controlCenterOpen = false
        timePopupOpen = false
        calendarOpen = false
        mediaPopupOpen = false
        clipboardOpen = false
    }
}

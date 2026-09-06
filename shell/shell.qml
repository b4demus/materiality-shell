pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/services"
import "root:/modules/background"
import "root:/modules/bar"
import "root:/modules/osd"
import "root:/modules/notifications"
import "root:/modules/launcher"
import "root:/modules/controlcenter"
import "root:/modules/lock"
import "root:/modules/settings"

ShellRoot {
    id: shell

    // ---- IPC: qs -c expressive ipc call <target> <fn> -------------------
    IpcHandler {
        target: "launcher"
        function toggle(): void { Bus.launcherOpen = !Bus.launcherOpen }
        function open(): void { Bus.launcherOpen = true }
        function close(): void { Bus.launcherOpen = false }
    }
    IpcHandler {
        target: "osd"
        function test(): void { Bus.osdTest() }
    }
    IpcHandler {
        target: "controlCenter"
        function toggle(): void { Bus.controlCenterOpen = !Bus.controlCenterOpen }
    }
    IpcHandler {
        target: "timePopup"
        function toggle(): void { Bus.calendarOpen = false; Bus.timePopupOpen = !Bus.timePopupOpen }
    }
    IpcHandler {
        target: "calendar"
        function toggle(): void { Bus.timePopupOpen = false; Bus.calendarOpen = !Bus.calendarOpen }
    }
    IpcHandler {
        target: "mediaPopup"
        function toggle(): void {
            Bus.timePopupOpen = false; Bus.calendarOpen = false
            Bus.mediaPopupOpen = !Bus.mediaPopupOpen
        }
    }
    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            Bus.timePopupOpen = false; Bus.calendarOpen = false; Bus.mediaPopupOpen = false
            Bus.clipboardOpen = !Bus.clipboardOpen
        }
    }
    IpcHandler {
        target: "settings"
        function open(): void { Bus.openSettings("") }
        function page(name: string): void { Bus.openSettings(name) }
        function close(): void { Bus.settingsOpen = false }
        function toggle(): void { Bus.settingsOpen = !Bus.settingsOpen }

        // Scriptable access to the same store the UI writes, so settings can be
        // driven from a shell script or a niri bind:
        //   qs -c expressive ipc call settings set bar.height 40
        function get(path: string): string {
            return JSON.stringify(Settings.val(path, null))
        }
        function set(path: string, value: string): string {
            let parsed
            try { parsed = JSON.parse(value) } catch (e) { parsed = value }
            Settings.set(path, parsed)
            return JSON.stringify(Settings.val(path, null))
        }
        function reset(section: string): void { Settings.reset(section) }
    }
    IpcHandler {
        target: "lock"
        function lock(): void { Bus.locked = true }
        function unlock(): void { Bus.locked = false }
        function toggle(): void { Bus.locked = !Bus.locked }
    }

    // ---- managers ------------------------------------------------------
    // QML singletons are constructed lazily, on first reference. The managers
    // below have to be alive for the whole session — they are what pushes the
    // settings store out to niri, the gamma ramps, the idle timers and the
    // automation rules — so the shell touches them once at startup rather than
    // waiting for a settings page to reference them.
    // A plain QtObject rather than Scope: Quickshell's Scope does not carry the
    // Component attached object, so Component.onCompleted never fires on it.
    QtObject {
        Component.onCompleted: {
            NiriConf.refresh()
            NightLight.refresh()
            Power.refreshIdle()
            Profiles.evaluate()
        }
    }

    // ---- per-screen surfaces ------------------------------------------
    Variants {
        model: Quickshell.screens
        delegate: Background {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    // ---- global overlays --------------------------------------------
    Osd {}
    MicOsd {}
    NotificationLayer {}
    Launcher {}
    ControlCenter {}
    MediaPopup {}
    TimePopup {}
    CalendarPopup {}
    ClipboardPopup {}
    LockScreen {}
    SettingsWindow {}
}

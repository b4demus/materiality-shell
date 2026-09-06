import QtQuick
import Quickshell
import Quickshell.Io
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "About"
    subtitle: "What this shell is running on, and where it keeps its files."
    maxWidth: 860

    property string quickshellVersion: ""
    property string niriVersion: ""
    property string kernel: ""
    property string distro: ""

    // ---- identity -----------------------------------------------------------
    MCard {
        width: parent.width
        tone: Colors.primaryContainer

        Row {
            width: parent.width
            spacing: Appearance.space.l

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 64; height: 64
                radius: Appearance.radius.l
                color: Colors.primary

                MIcon {
                    anchors.centerIn: parent
                    name: "auto_awesome"
                    size: 30
                    fill: 1
                    color: Colors.on.primary
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: "Materiality"
                    color: Colors.on.primaryContainer
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.headlineMedium
                    font.weight: Appearance.font.weightMedium
                }
                Text {
                    text: "A Material 3 Expressive desktop shell for Quickshell and niri"
                    color: Colors.on.primaryContainer
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodyMedium
                }
                Text {
                    text: "vibed by b4demus"
                    color: Colors.on.primaryContainer
                    opacity: 0.7
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodySmall
                }
            }
        }
    }

    // ---- versions -----------------------------------------------------------
    MSection {
        width: parent.width
        title: "System"
        icon: "info"

        Repeater {
            model: [
                { label: "Quickshell",   value: page.quickshellVersion, icon: "widgets" },
                { label: "niri",         value: page.niriVersion, icon: "view_column" },
                { label: "Session",      value: `Wayland · ${Quickshell.env("XDG_SESSION_TYPE") || "wayland"}`,
                  icon: "desktop_windows" },
                { label: "Distribution", value: page.distro, icon: "computer" },
                { label: "Kernel",       value: page.kernel, icon: "memory" },
                { label: "Outputs",      value: Displays.outputs.map(o => o.name).join(", ") || "—",
                  icon: "monitor" }
            ]

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    minHeight: 48
                    icon: modelData.icon
                    title: modelData.label

                    Text {
                        text: modelData.value || "…"
                        color: Colors.on.surfaceVariant
                        font.family: Appearance.monoFamily
                        font.pixelSize: Appearance.font.bodySmall
                    }
                }

                MDivider { width: parent.width; visible: index < 5 }
            }
        }
    }

    // ---- files --------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Where things live"
        icon: "folder"

        Repeater {
            model: [
                { label: "Shell source",    value: Files.shellDir, icon: "code" },
                { label: "Settings",        value: Settings.filePath, icon: "settings" },
                { label: "Palette",         value: `${Files.stateDir}/colors.json`, icon: "palette" },
                { label: "Wallpaper library", value: Wallpaper.catalogDir, icon: "wallpaper" },
                { label: "niri config",     value: `${Files.config}/niri/config.kdl`, icon: "description" }
            ]

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    minHeight: 48
                    icon: modelData.icon
                    title: modelData.label
                    subtitle: modelData.value
                }

                MDivider { width: parent.width; visible: index < 4 }
            }
        }
    }

    // ---- maintenance ---------------------------------------------------------
    MSection {
        width: parent.width
        title: "Configuration"
        icon: "build"

        MRow {
            width: parent.width
            icon: "refresh"
            title: "Reload the shell"
            subtitle: "Rebuilds every window from source without touching your session"
            clickable: true
            onClicked: Quickshell.reload(true)

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "download"
            title: "Export settings"
            subtitle: "Writes a copy of settings.json to your home directory"
            clickable: true
            onClicked: {
                Settings.exportTo(`${Files.home}/materiality-settings.json`)
                exported.open = true
            }

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "upload"
            title: "Import settings"
            subtitle: "Reads ~/materiality-settings.json and applies it"
            clickable: true
            onClicked: Settings.importFrom(`${Files.home}/materiality-settings.json`)

            MIcon { name: "chevron_right"; size: 20; color: Colors.on.surfaceVariant }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "restart_alt"
            title: "Reset every setting"
            subtitle: "Restores the defaults. Your wallpapers, niri config and profiles "
                    + "on disk are not deleted."
            clickable: true
            onClicked: resetDialog.open = true

            MIcon { name: "chevron_right"; size: 20; color: Colors.error }
        }
    }

    MDialog {
        id: resetDialog
        title: "Reset all settings?"
        message: "Everything on every page goes back to its default value. "
               + "This cannot be undone."
        icon: "restart_alt"
        destructive: true
        confirmText: "Reset"
        onConfirmed: Settings.reset("")
    }

    MDialog {
        id: exported
        title: "Settings exported"
        message: `Saved to ${Files.home}/materiality-settings.json`
        icon: "check_circle"
        cancelText: "Close"
        confirmText: ""
    }

    // ---- version probes ------------------------------------------------------
    Process {
        running: true
        command: ["sh", "-c",
            'printf "%s\\n" "$(qs --version 2>/dev/null | head -n1)" ' +
            '"$(niri --version 2>/dev/null | head -n1)" ' +
            '"$(uname -r)" ' +
            '"$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"']
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")
                page.quickshellVersion = l[0] || "unknown"
                page.niriVersion = l[1] || "unknown"
                page.kernel = l[2] || ""
                page.distro = l[3] || ""
            }
        }
    }
}

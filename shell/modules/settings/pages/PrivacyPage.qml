import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Privacy"
    subtitle: "Hardware kill-switches for the camera and microphone. When off, no "
            + "application can use the device — not just the ones that ask nicely."
    maxWidth: 880

    // ---- microphone -------------------------------------------------------
    MSection {
        width: parent.width
        title: "Microphone"
        icon: Privacy.micEnabled ? "mic" : "mic_off"
        description: "The default input is muted at PipeWire, so every app records "
                   + "silence. Also toggles from the bar chip and the Super+Shift+M "
                   + "/ mic-mute key — a small badge slides in from the top when it "
                   + "changes."

        MRow {
            width: parent.width
            icon: Privacy.micEnabled ? "mic" : "mic_off"
            title: "Allow apps to use the microphone"
            subtitle: !Privacy.micReady ? "No input device"
                      : Privacy.micEnabled
                        ? (Audio.source ? Audio.nodeLabel(Audio.source) : "Input live")
                        : "Muted — applications capture silence"

            MSwitch {
                checked: Privacy.micEnabled
                enabledSwitch: Privacy.micReady
                onToggled: c => Privacy.setMic(c)
            }
        }
    }

    // ---- camera ---------------------------------------------------------
    MSection {
        width: parent.width
        title: "Camera"
        icon: Privacy.cameraAllowed ? "photo_camera" : "no_photography"
        description: "Removes read access to every /dev/video* node while off."

        MRow {
            width: parent.width
            icon: Privacy.cameraAllowed ? "photo_camera" : "no_photography"
            title: "Allow apps to use the camera"
            subtitle: {
                if (!Privacy.cameraPresent) return "No camera detected — the choice is saved for later"
                if (!Privacy.cameraEnforceable)
                    return "Preference saved, but the shell can't change /dev/video* "
                         + "permissions here (needs a udev rule or elevated rights)"
                return Privacy.cameraAllowed
                    ? Privacy.cameraDeviceCount + (Privacy.cameraDeviceCount === 1 ? " device available" : " devices available")
                    : "Blocked for all applications"
            }

            MSwitch {
                checked: Privacy.cameraAllowed
                onToggled: c => Privacy.setCamera(c)
            }
        }
    }

    // ---- note ---------------------------------------------------------
    MSection {
        width: parent.width
        title: "How this works"
        icon: "info"

        MRow {
            width: parent.width
            icon: "shield"
            title: "Best-effort, no root"
            subtitle: "The microphone switch is absolute. The camera switch is as "
                    + "strong as the shell's permission to touch the device nodes."
        }
    }
}

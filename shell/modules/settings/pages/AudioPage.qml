import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Sound"
    subtitle: "Devices and per-application volume, straight from PipeWire."
    maxWidth: 880

    // ---- output -------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Output"
        icon: "volume_up"

        MSliderRow {
            width: parent.width
            icon: Audio.icon
            title: "Volume"
            subtitle: Audio.sink ? Audio.nodeLabel(Audio.sink) : "No output device"
            from: 0; to: 1; stepSize: 0.01
            valueText: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
            enabledRow: Audio.ready
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: Audio.muted ? "volume_off" : "volume_up"
            title: "Mute"

            MSwitch {
                checked: Audio.muted
                enabledSwitch: Audio.ready
                onToggled: c => Audio.toggleMute()
            }
        }
    }

    MSection {
        width: parent.width
        title: "Output device"
        icon: "speaker"

        Repeater {
            model: Audio.outputs

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MRow {
                    width: parent.width
                    icon: Audio.isDefaultSink(modelData) ? "check_circle" : "speaker"
                    title: Audio.nodeLabel(modelData)
                    subtitle: Audio.isDefaultSink(modelData) ? "Default output" : "Available"
                    clickable: true
                    onClicked: Audio.setDefaultSink(modelData)

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: "transparent"
                        border.width: 2
                        border.color: Audio.isDefaultSink(modelData) ? Colors.primary : Colors.outline
                        Rectangle {
                            anchors.centerIn: parent
                            width: 12; height: 12; radius: 6
                            color: Colors.primary
                            visible: Audio.isDefaultSink(modelData)
                        }
                    }
                }

                MDivider { width: parent.width; visible: index < Audio.outputs.length - 1 }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Audio.outputs.length === 0
            icon: "speaker"
            title: "No output devices"
            message: "PipeWire reports no audio sinks."
        }
    }

    // ---- input --------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Input"
        icon: "mic"

        MSliderRow {
            width: parent.width
            icon: Audio.micMuted ? "mic_off" : "mic"
            title: "Microphone volume"
            subtitle: Audio.source ? Audio.nodeLabel(Audio.source) : "No input device"
            from: 0; to: 1; stepSize: 0.01
            valueText: Audio.micMuted ? "Muted" : Math.round(Audio.micVolume * 100) + "%"
            enabledRow: Audio.micReady
            accent: Colors.tertiary
            value: Audio.micVolume
            onMoved: v => Audio.setMicVolume(v)
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: Audio.micMuted ? "mic_off" : "mic"
            title: "Mute microphone"

            MSwitch {
                checked: Audio.micMuted
                enabledSwitch: Audio.micReady
                onToggled: c => Audio.toggleMicMute()
            }
        }

        MDivider { width: parent.width; visible: Audio.inputs.length > 0 }

        Repeater {
            model: Audio.inputs

            delegate: MRow {
                required property var modelData
                width: parent.width
                icon: Audio.isDefaultSource(modelData) ? "check_circle" : "mic"
                title: Audio.nodeLabel(modelData)
                subtitle: Audio.isDefaultSource(modelData) ? "Default input" : "Available"
                clickable: true
                onClicked: Audio.setDefaultSource(modelData)

                Rectangle {
                    width: 22; height: 22; radius: 11
                    color: "transparent"
                    border.width: 2
                    border.color: Audio.isDefaultSource(modelData) ? Colors.primary : Colors.outline
                    Rectangle {
                        anchors.centerIn: parent
                        width: 12; height: 12; radius: 6
                        color: Colors.primary
                        visible: Audio.isDefaultSource(modelData)
                    }
                }
            }
        }
    }

    // ---- per-app ------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Applications"
        icon: "graphic_eq"
        description: "Anything currently playing audio. Levels here are per-stream and "
                   + "disappear with the app."

        Repeater {
            model: Audio.streams

            delegate: Column {
                required property var modelData
                required property int index
                width: parent.width

                MSliderRow {
                    width: parent.width
                    icon: Audio.streamIcon(modelData)
                    title: Audio.streamLabel(modelData)
                    from: 0; to: 1; stepSize: 0.01
                    valueText: (modelData.audio && modelData.audio.muted)
                               ? "Muted"
                               : Math.round(((modelData.audio && modelData.audio.volume) || 0) * 100) + "%"
                    value: (modelData.audio && modelData.audio.volume) || 0
                    onMoved: v => Audio.setNodeVolume(modelData, v)
                }

                MDivider { width: parent.width; visible: index < Audio.streams.length - 1 }
            }
        }

        MEmptyState {
            width: parent.width
            visible: Audio.streams.length === 0
            icon: "music_off"
            title: "Nothing is playing"
            message: "Start some audio and its stream will show up here."
        }
    }
}

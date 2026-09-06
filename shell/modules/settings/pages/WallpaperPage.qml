import QtQuick
import Quickshell
import "root:/config"
import "root:/components"
import "root:/services"
import "root:/modules/settings"

Page {
    id: page
    title: "Wallpaper"
    subtitle: "Picking a wallpaper also reseeds the Material You palette, so the "
              + "whole desktop retones with it."
    maxWidth: 1000

    property string filter: "all"        // all | favorites | recent | <collection>
    property string targetOutput: ""     // "" = every monitor

    // the filter chip currently in view is one of the user's own collections
    readonly property bool onCollection:
        filter !== "all" && filter !== "favorites" && filter !== "recent"

    readonly property var shown: {
        if (filter === "favorites") return Wallpaper.favorites
        if (filter === "recent") return Wallpaper.recent
        if (filter !== "all") return Wallpaper.collectionOf(filter)
        return Wallpaper.list
    }

    headerActions: [
        MButton {
            icon: "shuffle"
            label: "Shuffle"
            bg: Colors.surfaceContainerHigh
            fg: Colors.on.surfaceVariant
            hpad: Appearance.space.l
            enabled: Wallpaper.list.length > 1
            onClicked: Wallpaper.advance()
        },
        MButton {
            icon: "add_photo_alternate"
            label: "Add image"
            bg: Colors.primaryContainer
            fg: Colors.on.primaryContainer
            hpad: Appearance.space.l
            enabled: !Wallpaper.busy
            onClicked: Wallpaper.browse(page.targetOutput)
        }
    ]

    // ---- hero -------------------------------------------------------------
    MCard {
        width: parent.width
        tone: Colors.surfaceContainerLowest
        padding: Appearance.space.m

        Item {
            width: parent.width
            height: Math.round(width * 0.36)

            Rectangle {
                anchors.fill: parent
                radius: Appearance.radius.l
                color: Colors.surfaceContainerHigh
                clip: true

                Image {
                    anchors.fill: parent
                    source: Wallpaper.sourceFor(page.targetOutput)
                    fillMode: Wallpaper.fillModeFor()
                    asynchronous: true
                    cache: true
                    sourceSize.width: 1200
                }

                // Legibility scrim under the filename.
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.55; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: Appearance.space.l
                    spacing: 2

                    Text {
                        text: Wallpaper.hasWallpaper
                              ? Files.fileName(Wallpaper.pathFor(page.targetOutput))
                              : "No wallpaper set"
                        color: "#FFFFFF"
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.titleMedium
                        font.weight: Appearance.font.weightMedium
                    }
                    Text {
                        visible: Wallpaper.hasWallpaper
                        text: page.targetOutput ? `On ${page.targetOutput}` : "On every monitor"
                        color: Qt.rgba(1, 1, 1, 0.75)
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.font.labelMedium
                    }
                }

                MButton {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Appearance.space.l
                    visible: Wallpaper.hasWallpaper
                    icon: Wallpaper.isFavorite(Wallpaper.pathFor(page.targetOutput))
                          ? "favorite" : "favorite_border"
                    iconFill: Wallpaper.isFavorite(Wallpaper.pathFor(page.targetOutput)) ? 1 : 0
                    bg: Qt.rgba(0, 0, 0, 0.45)
                    fg: "#FFFFFF"
                    onClicked: Wallpaper.toggleFavorite(Wallpaper.pathFor(page.targetOutput))
                }
            }
        }
    }

    // ---- monitors ---------------------------------------------------------
    MSection {
        width: parent.width
        visible: Displays.outputs.length > 1
        title: "Monitors"
        icon: "desktop_windows"

        MRow {
            width: parent.width
            icon: "content_copy"
            title: "Same wallpaper everywhere"
            subtitle: Wallpaper.perOutput
                      ? "Each monitor keeps its own image"
                      : "One image spans every monitor"

            MSwitch {
                checked: !Wallpaper.perOutput
                onToggled: c => Settings.set("wallpaper.mode", c ? "same" : "per-output")
            }
        }

        MDivider { width: parent.width; visible: Wallpaper.perOutput }

        Column {
            width: parent.width
            visible: Wallpaper.perOutput
            spacing: Appearance.space.s

            Text {
                text: "Editing wallpaper for"
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.labelLarge
            }
            Flow {
                width: parent.width
                spacing: Appearance.space.s

                Repeater {
                    model: Displays.outputs
                    delegate: MChip {
                        required property var modelData
                        label: modelData.name
                        icon: "monitor"
                        selected: page.targetOutput === modelData.name
                        onClicked: page.targetOutput = modelData.name
                    }
                }
                MChip {
                    label: "All monitors"
                    icon: "select_all"
                    selected: page.targetOutput === ""
                    onClicked: page.targetOutput = ""
                }
            }
        }
    }

    // ---- scaling ------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Scaling"
        icon: "aspect_ratio"

        MRow {
            width: parent.width
            icon: Wallpaper.scalingModes.filter(m => m.value === Wallpaper.scaling)[0]
                  ? Wallpaper.scalingModes.filter(m => m.value === Wallpaper.scaling)[0].icon
                  : "crop_free"
            title: "How the image fills the screen"
            subtitle: {
                const m = Wallpaper.scalingModes.filter(x => x.value === Wallpaper.scaling)[0]
                return m ? m.hint : ""
            }

            MSelect {
                width: 220
                model: Wallpaper.scalingModes.map(m => ({ value: m.value, label: m.label, icon: m.icon }))
                value: Wallpaper.scaling
                onPicked: v => Settings.set("wallpaper.scaling", v)
            }
        }
    }

    // ---- library ------------------------------------------------------------
    MSection {
        width: parent.width
        title: "Library"
        icon: "photo_library"
        description: "Every image you pick is kept here as a link — removing one from "
                   + "the library never deletes the original file."

        Flow {
            width: parent.width
            spacing: Appearance.space.s

            MChip {
                label: `All (${Wallpaper.list.length})`
                selected: page.filter === "all"
                onClicked: page.filter = "all"
            }
            MChip {
                label: `Favourites (${Wallpaper.favorites.length})`
                icon: "favorite"
                selected: page.filter === "favorites"
                onClicked: page.filter = "favorites"
            }
            MChip {
                label: "Recent"
                icon: "history"
                selected: page.filter === "recent"
                onClicked: page.filter = "recent"
            }
            Repeater {
                model: Wallpaper.collectionNames()
                delegate: MChip {
                    required property string modelData
                    label: modelData
                    icon: "folder"
                    selected: page.filter === modelData
                    onClicked: page.filter = modelData
                }
            }
            MChip {
                label: "New collection"
                icon: "create_new_folder"
                showCheck: false
                onClicked: newCollection.open = true
            }

            // act on the collection currently in view
            MChip {
                visible: page.onCollection
                label: "Add wallpapers"
                icon: "library_add"
                showCheck: false
                onClicked: fillCollection.open = true
            }
            MChip {
                visible: page.onCollection
                label: "Delete collection"
                icon: "delete"
                showCheck: false
                onClicked: deleteCollection.open = true
            }
        }

        // the grid
        Item {
            width: parent.width
            implicitHeight: page.shown.length === 0 ? empty.implicitHeight : grid.implicitHeight

            Grid {
                id: grid
                width: parent.width
                columns: Math.max(2, Math.floor(width / 200))
                columnSpacing: Appearance.space.m
                rowSpacing: Appearance.space.m
                readonly property real cellW: (width - columnSpacing * (columns - 1)) / columns

                Repeater {
                    model: page.shown

                    delegate: Rectangle {
                        id: tile
                        required property string modelData
                        readonly property bool isCurrent:
                            modelData === Wallpaper.pathFor(page.targetOutput)

                        width: grid.cellW
                        height: Math.round(grid.cellW * 0.62)
                        radius: Appearance.radius.m
                        color: Colors.surfaceContainerHighest
                        clip: true

                        scale: tileMa.pressed ? 0.97 : 1
                        Behavior on scale {
                            SpringAnimation {
                                spring: Motion.spatialFast.spring; damping: Motion.spatialFast.damping
                                mass: Motion.spatialFast.mass; epsilon: Motion.spatialFast.epsilon
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: "file://" + tile.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 400
                        }

                        // selection frame — painted on top of the image so the
                        // rounded corners stay crisp instead of notching around
                        // a square, border-inset image
                        Rectangle {
                            z: 5
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            visible: tile.isCurrent
                            border.width: 3
                            border.color: Colors.primary
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Colors.on.surface
                            opacity: tileMa.pressed ? Appearance.statePress
                                     : tileMa.containsMouse ? Appearance.stateHover : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
                        }

                        // hover actions
                        Row {
                            z: 2
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            spacing: 4
                            opacity: tileMa.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.durShort } }

                            Rectangle {
                                width: 26; height: 26; radius: 13
                                color: Qt.rgba(0, 0, 0, 0.55)
                                MIcon {
                                    anchors.centerIn: parent
                                    name: Wallpaper.isFavorite(tile.modelData)
                                          ? "favorite" : "favorite_border"
                                    fill: Wallpaper.isFavorite(tile.modelData) ? 1 : 0
                                    size: 15
                                    color: "#FFFFFF"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Wallpaper.toggleFavorite(tile.modelData)
                                }
                            }
                            Rectangle {
                                width: 26; height: 26; radius: 13
                                color: Qt.rgba(0, 0, 0, 0.55)
                                MIcon {
                                    anchors.centerIn: parent
                                    name: "close"
                                    size: 15
                                    color: "#FFFFFF"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Wallpaper.remove(tile.modelData)
                                }
                            }
                        }

                        // collection membership toggle
                        Rectangle {
                            z: 2
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            visible: page.onCollection
                            width: 26; height: 26; radius: 13
                            color: Qt.rgba(0, 0, 0, 0.55)
                            MIcon {
                                anchors.centerIn: parent
                                name: "playlist_remove"
                                size: 15
                                color: "#FFFFFF"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wallpaper.setInCollection(page.filter, tile.modelData, false)
                            }
                        }

                        MouseArea {
                            id: tileMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    addTo.target = tile.modelData
                                    addTo.open = true
                                } else {
                                    Wallpaper.set(tile.modelData, page.targetOutput)
                                }
                            }
                        }
                    }
                }
            }

            MEmptyState {
                id: empty
                width: parent.width
                visible: page.shown.length === 0
                icon: "image"
                title: page.filter === "all" ? "Your library is empty" : "Nothing here yet"
                message: page.filter === "all"
                         ? "Add an image and it will be kept here for next time."
                         : page.onCollection
                           ? "Add wallpapers from your library, or right-click any wallpaper to file it here."
                           : "Right-click any wallpaper to file it into a collection."
                actionLabel: page.filter === "all" ? "Add image"
                             : page.onCollection ? "Add wallpapers" : ""
                onActionClicked: page.onCollection && page.filter !== "all"
                                 ? fillCollection.open = true
                                 : Wallpaper.browse(page.targetOutput)
            }
        }
    }

    // ---- slideshow -----------------------------------------------------------
    MSection {
        width: parent.width
        title: "Slideshow"
        icon: "slideshow"

        MRow {
            width: parent.width
            icon: "play_circle"
            title: "Rotate the wallpaper"
            subtitle: Wallpaper.slideshow
                      ? `Changes every ${Math.round(Wallpaper.slideshowInterval / 60)} min · `
                        + `${Wallpaper.slideshowPool().length} images`
                      : "Off"

            MSwitch {
                checked: Wallpaper.slideshow
                onToggled: c => Settings.set("wallpaper.slideshow.enabled", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "timer"
            title: "Interval"
            enabledRow: Wallpaper.slideshow

            MSelect {
                width: 200
                enabledSelect: Wallpaper.slideshow
                model: [
                    { value: 60,    label: "Every minute" },
                    { value: 300,   label: "Every 5 minutes" },
                    { value: 900,   label: "Every 15 minutes" },
                    { value: 1800,  label: "Every 30 minutes" },
                    { value: 3600,  label: "Every hour" },
                    { value: 21600, label: "Every 6 hours" }
                ]
                value: Wallpaper.slideshowInterval
                onPicked: v => Settings.set("wallpaper.slideshow.intervalSec", v)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "shuffle"
            title: "Shuffle"
            subtitle: "Pick at random instead of in order"
            enabledRow: Wallpaper.slideshow

            MSwitch {
                checked: Wallpaper.slideshowRandom
                enabledSwitch: Wallpaper.slideshow
                onToggled: c => Settings.set("wallpaper.slideshow.random", c)
            }
        }

        MDivider { width: parent.width }

        MRow {
            width: parent.width
            icon: "folder"
            title: "Source"
            enabledRow: Wallpaper.slideshow

            MSelect {
                width: 200
                enabledSelect: Wallpaper.slideshow
                model: [{ value: "", label: "Whole library" }].concat(
                    Wallpaper.collectionNames().map(n => ({ value: n, label: n, icon: "folder" })))
                value: Wallpaper.slideshowCollection
                onPicked: v => Settings.set("wallpaper.slideshow.collection", v)
            }
        }
    }

    // ---- dialogs --------------------------------------------------------------
    MDialog {
        id: newCollection
        title: "New collection"
        message: "Group wallpapers so a slideshow can draw from just one set."
        icon: "create_new_folder"
        confirmText: "Create"
        confirmEnabled: nameField.text.trim().length > 0

        MTextField {
            id: nameField
            width: parent.width
            label: "Collection name"
            onAccepted: if (text.trim()) newCollection.confirmed()
        }

        onConfirmed: {
            Wallpaper.createCollection(nameField.text.trim())
            page.filter = nameField.text.trim()
            nameField.text = ""
        }
        onCancelled: nameField.text = ""
    }

    MDialog {
        id: addTo
        property string target: ""
        title: "Add to collection"
        message: Files.fileName(target)
        icon: "playlist_add"
        cancelText: "Done"
        confirmText: ""

        Column {
            width: parent.width
            spacing: Appearance.space.s

            Repeater {
                model: Wallpaper.collectionNames()
                delegate: MRow {
                    required property string modelData
                    width: parent.width
                    minHeight: 44
                    icon: "folder"
                    title: modelData

                    MSwitch {
                        checked: Wallpaper.collectionOf(modelData).indexOf(addTo.target) >= 0
                        onToggled: c => Wallpaper.setInCollection(modelData, addTo.target, c)
                    }
                }
            }

            Text {
                width: parent.width
                visible: Wallpaper.collectionNames().length === 0
                text: "No collections yet — create one from the Library chips above."
                wrapMode: Text.WordWrap
                color: Colors.on.surfaceVariant
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.font.bodySmall
            }
        }
    }

    MDialog {
        id: fillCollection
        dialogWidth: 460
        title: "Add wallpapers"
        message: page.onCollection ? `Into “${page.filter}”` : ""
        icon: "library_add"
        cancelText: "Done"
        confirmText: ""

        MScroll {
            width: parent.width
            height: Math.min(360, fillList.implicitHeight)
            contentHeight: fillList.implicitHeight

            Column {
                id: fillList
                width: parent.width
                spacing: Appearance.space.s

                Repeater {
                    model: Wallpaper.list
                    delegate: MRow {
                        required property string modelData
                        width: parent.width
                        minHeight: 48
                        icon: "wallpaper"
                        title: Files.fileName(modelData)

                        MSwitch {
                            checked: page.onCollection
                                     && Wallpaper.collectionOf(page.filter).indexOf(modelData) >= 0
                            onToggled: c => Wallpaper.setInCollection(page.filter, modelData, c)
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: Wallpaper.list.length === 0
                    text: "Your library is empty — use “Add image” first."
                    wrapMode: Text.WordWrap
                    color: Colors.on.surfaceVariant
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.font.bodySmall
                }
            }
        }
    }

    MDialog {
        id: deleteCollection
        title: "Delete collection"
        message: page.onCollection
                 ? `“${page.filter}” will be removed. The wallpapers in it stay in your library.`
                 : ""
        icon: "delete"
        destructive: true
        confirmText: "Delete"
        onConfirmed: {
            const name = page.filter
            page.filter = "all"
            Wallpaper.deleteCollection(name)
        }
    }
}

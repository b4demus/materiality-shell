import QtQuick
import "root:/config"

// A little cat kaomoji sitting right of the clock. Re-rolls every few minutes,
// or on click.
Item {
    id: root
    implicitWidth: label.implicitWidth + Appearance.space.s * 2
    implicitHeight: 24

    readonly property var faces: [
        "(=^･ω･^=)", "(=ↀωↀ=)", "(ΦωΦ)", "(=ＴェＴ=)", "( =ω= )",
        "(^･o･^)ﾉ", "(=ＴωＴ=)", "ヾ(=ﾟ･ﾟ=)ﾉ", "=^._.^=", "(=①ω①=)",
        "(ↀДↀ)✧", "ﾐ(ΦωΦ)ﾐ", "(=ΦωΦ=)", "(=ＸエＸ=)", "( ฅ•ω•ฅ )"
    ]
    property int idx: Math.floor(Math.random() * faces.length)

    function roll() {
        if (faces.length < 2)
            return
        var n = idx
        while (n === idx)
            n = Math.floor(Math.random() * faces.length)
        idx = n
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.roll()
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radius.full
        color: Colors.barOnSurface
        opacity: ma.pressed ? Appearance.statePress
                 : ma.containsMouse ? Appearance.stateHover : 0
        Behavior on opacity { NumberAnimation { duration: Motion.durShort } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.faces[root.idx]
        color: Colors.barOnSurfaceVariant
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.font.labelMedium

        // tiny bounce when it re-rolls
        transform: Scale { id: pop; origin.x: label.width / 2; origin.y: label.height / 2 }
        onTextChanged: bump.restart()
        SequentialAnimation {
            id: bump
            NumberAnimation { target: pop; properties: "xScale,yScale"; to: 1.18; duration: 90 }
            NumberAnimation { target: pop; properties: "xScale,yScale"; to: 1.0; duration: 160; easing.type: Easing.OutBack }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.roll()
    }
}

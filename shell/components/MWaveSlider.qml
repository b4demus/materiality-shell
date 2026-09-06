import QtQuick
import "root:/config"

// Material 3 Expressive "wavy" progress / seek track: the played portion is a
// flowing sine wave, the remaining portion a flat rounded line with a stop dot,
// a vertical handle between them. Drag to seek when `interactive`.
Item {
    id: root

    property real value: 0            // 0..1
    property bool interactive: true
    property bool playing: false      // wave flows + gains amplitude while true
    property color activeColor: Colors.primary
    property color trackColor: Colors.secondaryContainer
    property real stroke: 5           // line thickness
    property real amplitude: 4        // wave peak height (px)
    property real waveLength: 28      // px per full wave
    property real handleWidth: 4
    property real gap: 6              // symmetric gap: handle -> each segment

    signal moved(real value)

    implicitHeight: amplitude * 2 + stroke + 8
    implicitWidth: 200

    readonly property real frac: Math.max(0, Math.min(1, value))
    readonly property real usable: width - handleWidth
    readonly property real activeX: frac * usable

    // flowing phase
    property real phase: 0
    NumberAnimation on phase {
        running: root.playing && root.visible
        from: 0; to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }
    // amplitude eases toward flat when paused
    property real amp: playing ? amplitude : amplitude * 0.28
    Behavior on amp { NumberAnimation { duration: Motion.durMedium; easing.type: Motion.easeStandard } }

    onActiveXChanged: cv.requestPaint()
    onPhaseChanged: cv.requestPaint()
    onAmpChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onActiveColorChanged: cv.requestPaint()
    onTrackColorChanged: cv.requestPaint()

    Canvas {
        id: cv
        anchors.fill: parent
        antialiasing: true

        function rrect(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.arcTo(x + w, y, x + w, y + h, r)
            ctx.arcTo(x + w, y + h, x, y + h, r)
            ctx.arcTo(x, y + h, x, y, r)
            ctx.arcTo(x, y, x + w, y, r)
            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const midY = Math.round(height / 2)
            const ax = root.activeX
            const amp = root.amp
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            // inactive flat line (right of the handle)
            const inStart = Math.min(width - 3, ax + root.handleWidth + root.gap)
            if (width - 3 - inStart > 1) {
                ctx.strokeStyle = root.trackColor
                ctx.lineWidth = root.stroke
                ctx.beginPath()
                ctx.moveTo(inStart, midY)
                ctx.lineTo(width - 3, midY)
                ctx.stroke()
            }

            // stop dot at the far end
            ctx.fillStyle = root.activeColor
            ctx.beginPath()
            ctx.arc(width - 2.5, midY, root.stroke / 2 + 0.5, 0, Math.PI * 2)
            ctx.fill()

            // active wavy segment (left of the handle) — stops `gap` short of it
            const activeEnd = Math.max(0, ax - root.gap)
            if (activeEnd > 1.5) {
                ctx.strokeStyle = root.activeColor
                ctx.lineWidth = root.stroke
                ctx.beginPath()
                const k = (Math.PI * 2) / root.waveLength
                for (let x = 0; x <= activeEnd; x += 1.5) {
                    const y = midY + amp * Math.sin(k * x - root.phase)
                    x === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
                }
                ctx.stroke()
            }

            // handle
            ctx.fillStyle = root.activeColor
            const hh = amp * 2 + root.stroke + 4
            cv.rrect(ctx, ax, midY - hh / 2, root.handleWidth, hh, root.handleWidth / 2)
            ctx.fill()
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        onPressed: mouse => setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) setFromX(mouse.x) }
        function setFromX(px) {
            const v = Math.max(0, Math.min(1, (px - root.handleWidth / 2) / root.usable))
            root.value = v
            root.moved(v)
        }
    }
}

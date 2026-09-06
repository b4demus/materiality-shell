import QtQuick
import "root:/config"

// One Material-style shape, drawn procedurally.
//
// Two generators cover the whole set: a rounded regular polygon (triangle,
// diamond, pentagon, square…) and a polar blob r(θ) = R·(1 + a·cos(nθ))
// (clover, flower, burst). That keeps the family self-contained — no vendored
// shape library — while still giving the varied silhouettes Material uses.
Canvas {
    id: root

    // One of `shapes` below.
    property string shape: "circle"
    property color color: Colors.primary
    property real size: 18
    // A little per-instance rotation stops a row of them looking stamped.
    property real rotation_: 0

    readonly property var shapes: [
        "circle", "clover", "pill", "burst", "diamond",
        "flower", "pentagon", "square", "triangle"
    ]

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    onColorChanged: requestPaint()
    onShapeChanged: requestPaint()
    onSizeChanged: requestPaint()
    onRotation_Changed: requestPaint()

    // ---- generators ------------------------------------------------------
    // A regular n-gon with its corners rounded off. arcTo does the rounding
    // between each pair of edges; we walk edge midpoint → corner → midpoint so
    // the path never needs an explicit start corner.
    function _poly(ctx, cx, cy, r, n, rot, corner) {
        const pts = []
        for (let i = 0; i < n; i++) {
            const a = rot + i * 2 * Math.PI / n
            pts.push([cx + r * Math.cos(a), cy + r * Math.sin(a)])
        }
        const mid = (p, q) => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2]
        const start = mid(pts[n - 1], pts[0])
        ctx.beginPath()
        ctx.moveTo(start[0], start[1])
        for (let i = 0; i < n; i++) {
            const cur = pts[i]
            const m = mid(cur, pts[(i + 1) % n])
            ctx.arcTo(cur[0], cur[1], m[0], m[1], corner)
            ctx.lineTo(m[0], m[1])
        }
        ctx.closePath()
    }

    // Smooth lobed blob. `amp` is how far the lobes push out, `lobes` how many.
    function _blob(ctx, cx, cy, r, lobes, amp, rot) {
        const steps = 160
        ctx.beginPath()
        for (let i = 0; i <= steps; i++) {
            const t = rot + i / steps * 2 * Math.PI
            const rr = r * (1 + amp * Math.cos(lobes * t))
            const x = cx + rr * Math.cos(t)
            const y = cy + rr * Math.sin(t)
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
        }
        ctx.closePath()
    }

    function _pill(ctx, cx, cy, r) {
        const w = r * 2, h = r * 1.25, rad = h / 2
        const x = cx - w / 2, y = cy - h / 2
        ctx.beginPath()
        ctx.moveTo(x + rad, y)
        ctx.lineTo(x + w - rad, y)
        ctx.arcTo(x + w, y, x + w, y + rad, rad)
        ctx.lineTo(x + w, y + h - rad)
        ctx.arcTo(x + w, y + h, x + w - rad, y + h, rad)
        ctx.lineTo(x + rad, y + h)
        ctx.arcTo(x, y + h, x, y + h - rad, rad)
        ctx.lineTo(x, y + rad)
        ctx.arcTo(x, y, x + rad, y, rad)
        ctx.closePath()
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const c = width / 2
        // leave a hair of room so the lobed shapes don't clip at the edge
        const r = c * 0.92
        const q = Math.PI / 2
        const rot = root.rotation_ * Math.PI / 180

        switch (root.shape) {
        case "clover":   _blob(ctx, c, c, r * 0.84, 4, 0.20, rot + q / 2); break
        case "flower":   _blob(ctx, c, c, r * 0.88, 6, 0.12, rot); break
        case "burst":    _blob(ctx, c, c, r * 0.90, 12, 0.09, rot); break
        case "pill":     _pill(ctx, c, c, r * 0.92); break
        case "triangle": _poly(ctx, c, c, r, 3, rot - q, r * 0.20); break
        case "diamond":  _poly(ctx, c, c, r, 4, rot - q, r * 0.30); break
        case "pentagon": _poly(ctx, c, c, r, 5, rot - q, r * 0.34); break
        case "square":   _poly(ctx, c, c, r, 4, rot + q / 2, r * 0.55); break
        default:         ctx.beginPath(); ctx.arc(c, c, r * 0.88, 0, 2 * Math.PI); ctx.closePath()
        }

        ctx.fillStyle = root.color
        ctx.fill()
    }
}

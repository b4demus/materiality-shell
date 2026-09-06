pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// niri compositor integration via its native JSON IPC.
// Quickshell 0.2.x ships no niri module, so we read `niri msg --json event-stream`
// directly and mirror the bits the bar needs.
Singleton {
    id: root

    // Array of workspace objects: { id, idx, name, output, is_active, is_focused, is_urgent, active_window_id }
    property var workspaces: []
    property int focusedWorkspaceId: -1

    // Focused window
    property int focusedWindowId: -1
    property string focusedTitle: ""
    property string focusedAppId: ""
    property bool focusedFullscreen: false

    property bool connected: false

    // Internal window store keyed by id
    property var _windows: ({})
    // { <output name>: { w, h } } logical sizes, for fullscreen detection
    property var _outputs: ({})

    function workspacesFor(output) {
        return (workspaces || [])
            .filter(w => !output || w.output === output)
            .sort((a, b) => a.idx - b.idx)
    }

    function focusWorkspace(idx) {
        actionProc.exec(["niri", "msg", "action", "focus-workspace", String(idx)])
    }
    function focusWorkspaceId(id) {
        const w = (workspaces || []).find(x => x.id === id)
        if (w) focusWorkspace(w.idx)
    }

    // ---- event stream ------------------------------------------------------
    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => root._onEvent(line)
        }
        onRunningChanged: if (!running) root.connected = false
        onExited: reconnect.restart()
    }

    Timer {
        id: reconnect
        interval: 1500
        onTriggered: stream.running = true
    }

    Process { id: actionProc; function exec(c) { command = c; running = true } }

    // ---- one-shot seeding -------------------------------------------------
    Process {
        id: seedWs
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector { onStreamFinished: root._seedWorkspaces(text) }
    }
    Process {
        id: seedWin
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector { onStreamFinished: root._seedWindows(text) }
    }
    Process {
        id: seedOut
        command: ["niri", "msg", "--json", "outputs"]
        stdout: StdioCollector { onStreamFinished: root._seedOutputs(text) }
    }

    Component.onCompleted: {
        seedWs.running = true
        seedWin.running = true
        seedOut.running = true
    }

    function _seedOutputs(txt) {
        try {
            const d = JSON.parse(txt)
            const map = {}
            for (const name in d) {
                const l = d[name] && d[name].logical
                if (l) map[name] = { w: l.width, h: l.height }
            }
            root._outputs = map
            _applyFocusedWindow()
        } catch (e) {}
    }

    function _seedWorkspaces(txt) {
        try {
            const arr = JSON.parse(txt)
            if (Array.isArray(arr)) {
                root.workspaces = arr
                const f = arr.find(w => w.is_focused)
                if (f) root.focusedWorkspaceId = f.id
            }
        } catch (e) {}
    }

    function _seedWindows(txt) {
        try {
            const arr = JSON.parse(txt)
            if (!Array.isArray(arr)) return
            const map = {}
            for (const w of arr) map[w.id] = w
            root._windows = map
            const f = arr.find(w => w.is_focused)
            if (f) { root.focusedWindowId = f.id; _applyFocusedWindow() }
        } catch (e) {}
    }

    // ---- event handling -------------------------------------------------
    function _onEvent(line) {
        let ev
        try { ev = JSON.parse(line) } catch (e) { return }
        root.connected = true

        if (ev.WorkspacesChanged) {
            root.workspaces = ev.WorkspacesChanged.workspaces || []
            const f = root.workspaces.find(w => w.is_focused)
            if (f) root.focusedWorkspaceId = f.id
        } else if (ev.WorkspaceActivated) {
            _activateWorkspace(ev.WorkspaceActivated.id, ev.WorkspaceActivated.focused)
        } else if (ev.WorkspaceActiveWindowChanged) {
            _setWorkspaceActiveWindow(ev.WorkspaceActiveWindowChanged.workspace_id,
                                      ev.WorkspaceActiveWindowChanged.active_window_id)
        } else if (ev.WorkspaceUrgencyChanged) {
            _patchWorkspace(ev.WorkspaceUrgencyChanged.id, { is_urgent: ev.WorkspaceUrgencyChanged.urgent })
        } else if (ev.WindowsChanged) {
            const map = {}
            for (const w of (ev.WindowsChanged.windows || [])) map[w.id] = w
            root._windows = map
            const f = (ev.WindowsChanged.windows || []).find(w => w.is_focused)
            root.focusedWindowId = f ? f.id : -1
            _applyFocusedWindow()
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window
            if (w) {
                const map = root._windows
                map[w.id] = w
                root._windows = map
                if (w.is_focused) root.focusedWindowId = w.id
                if (root.focusedWindowId === w.id) _applyFocusedWindow()
            }
        } else if (ev.WindowClosed) {
            const map = root._windows
            delete map[ev.WindowClosed.id]
            root._windows = map
            if (root.focusedWindowId === ev.WindowClosed.id) {
                root.focusedWindowId = -1
                _applyFocusedWindow()
            }
        } else if (ev.WindowFocusChanged) {
            root.focusedWindowId = (ev.WindowFocusChanged.id === null || ev.WindowFocusChanged.id === undefined)
                ? -1 : ev.WindowFocusChanged.id
            _applyFocusedWindow()
        } else if (ev.OutputsChanged || ev.OutputConfigChanged) {
            seedOut.running = true
        }
    }

    function _activateWorkspace(id, focused) {
        const list = (root.workspaces || []).slice()
        const target = list.find(w => w.id === id)
        if (!target) return
        for (const w of list) {
            if (w.output === target.output) w.is_active = (w.id === id)
            if (focused) w.is_focused = (w.id === id)
        }
        root.workspaces = list
        if (focused) root.focusedWorkspaceId = id
    }

    function _patchWorkspace(id, patch) {
        const list = (root.workspaces || []).slice()
        const w = list.find(x => x.id === id)
        if (!w) return
        Object.assign(w, patch)
        root.workspaces = list
    }

    function _setWorkspaceActiveWindow(wsId, winId) {
        _patchWorkspace(wsId, { active_window_id: winId })
    }

    function _applyFocusedWindow() {
        const w = root._windows[root.focusedWindowId]
        root.focusedTitle = w && w.title ? w.title : ""
        root.focusedAppId = w && w.app_id ? w.app_id : ""

        // niri 26.x exposes no `is_fullscreen`, so infer it: a fullscreen window
        // is the only tiled window that reaches the full output height (a normal
        // one is short by the bar's exclusion zone).
        let fs = false
        if (w && w.layout) {
            const sz = w.layout.window_size || w.layout.tile_size
            const ws = (root.workspaces || []).find(x => x.id === w.workspace_id)
            const out = ws && root._outputs[ws.output]
            if (sz && out && sz[1] >= out.h - 6 && sz[0] >= out.w - 6)
                fs = true
        }
        root.focusedFullscreen = fs
    }
}

// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   H   I   V   E                                                          │
// │   the wallpaper selector · not built into the bar                        │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../theme"
import "../services"

// The desk's wallpapers as a honeycomb: each picture cut into a hexagon and
// hung in wax, the comb floating under the bar's airspace on a scrim. A click
// on a cell hands the path to the service — the transition machinery decides
// how the wallpaper actually changes — Escape, or a click on the dark, closes
// the hive.
//
//   SUPER + W      the hive
//   qs ipc call wallpaper hive [open|close|toggle]
PanelWindow {
    id: root

    property bool open: false

    function closeDown(): void {
        root.open = false
    }

    function openUp(): void {
        if (!root.open)
            WallpaperService.scan()
        root.open = true
    }

    // The wax is pre-cut: on the first open a helper crops every wallpaper
    // into a small thumb in the cache, and cells read from it rather than
    // decoding a 4K picture for a 160-pixel cell. Pages never pop in.
    property var thumbs: ({})
    property bool thumbsStarted: false

    function prepThumbs(): void {
        if (root.thumbsStarted || comb.cells.length === 0)
            return
        root.thumbsStarted = true
        // The wax is asked for by what it displays: a cut per picture, a
        // blurred cut per motion cell — with the sharp poster beside it, so
        // a hover resolves the blur. `b` marks the blur.
        const list = comb.cells.map(c => ({
            p: c.motion && c.poster !== "" ? c.poster : c.path,
            b: c.motion && c.poster !== ""
        }))
        thumbsProcess.command = [
            "python3", Quickshell.shellPath("scripts/hive_thumbs.py"),
            JSON.stringify(list)
        ]
        thumbsProcess.running = true
    }

    Process {
        id: thumbsProcess

        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.thumbs = JSON.parse(text)
                } catch (e) {
                    root.thumbs = ({})
                }
            }
        }
    }

    function toggle(): void {
        root.open ? root.closeDown() : root.openUp()
    }

    // No scan on boot; the first open asks for the folder.
    Component.onCompleted: {
        root.openChanged.connect(() => {
            if (root.open && comb.cells.length === 0)
                WallpaperService.scan()
        })
        comb.cellsChanged.connect(root.prepThumbs)
        root.prepThumbs()
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    visible: root.open
    color: "transparent"
    WlrLayershell.namespace: "nocturnus-hive"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ── THE DARK ─────────────────────────────────────────────────────────────
    //
    // Nothing paints behind the comb: the hive asks for the desk itself, so
    // the MouseArea is silent glass — it only listens, catching the click
    // that lands off the comb (closing the hive) and the wheel (drifting the
    // pages).
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        onClicked: root.closeDown()
        // The wheel drifts the hive through the stack.
        onWheel: wheel => comb.turn(wheel.angleDelta.y < 0 ? 1 : -1)
    }

    // ── THE COMB ─────────────────────────────────────────────────────────────
    //
    // Pointy-top hexagons: columns √3·R apart, rows 1.5·R, odd rows staggered
    // half a column. Seven cells to a row; the comb centres itself.
    Item {
        id: comb

        readonly property real radius: 92
        readonly property int perRow: 7
        readonly property real side: comb.radius * Math.sqrt(3)
        readonly property real pad: 4

        readonly property var stills: WallpaperService.wallpapers.map(w => ({
            path: w.path,
            poster: "",
            motion: false,
            name: w.name
        }))

        readonly property var moving: WallpaperService.animated.map(entry => ({
            path: entry.path,
            poster: entry.poster,
            motion: true,
            name: entry.name
        }))

        readonly property var cells: comb.stills.concat(comb.moving)

        // The hive drifts: the folder holds hundreds, so the comb shows a
        // page at a time and the wheel walks the stack. Twenty-eight cells —
        // four staggered rows of seven — sit uniform under the bar's airspace.
        property int page: 0
        readonly property int perPage: 28
        readonly property int pages: Math.max(1, Math.ceil(comb.cells.length / comb.perPage))
        readonly property var pageCells: comb.cells.slice(
            comb.page * comb.perPage, (comb.page + 1) * comb.perPage)

        function turn(drift: int): void {
            const at = comb.page + drift
            if (at < 0 || at >= comb.pages || turnAnim.running)
                return
            comb.drift = drift
            turnAnim.restart()
        }

        // The slide: one short pass. The stack turns first, and the next
        // honeycomb carries the slide a little way with it — a settle, not
        // a crossing — then the wave of wax lands it.
        property int drift: 0
        property real transitX: 0

        transform: Translate { x: comb.transitX }

        SequentialAnimation {
            id: turnAnim

            ScriptAction { script: comb.page += comb.drift }
            NumberAnimation {
                target: comb
                property: "transitX"
                from: comb.drift * 120
                to: 0
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        // The desk's own picture, chosen or playing: the cell that matches
        // wears the accent.
        readonly property string pickCurrent: WallpaperService.chosen

        // Four rows always — the comb never shrinks on a short page; cells
        // land at the bottom and the empty rows stay invisible.
        readonly property int rows: Math.max(1, Math.ceil(comb.pageCells.length / comb.perRow))
        readonly property real spanX: comb.perRow * comb.side + comb.pad * 2
            + (comb.rows > 1 ? comb.side / 2 : 0)
        readonly property real spanY: (comb.rows - 1) * comb.radius * 1.5
            + comb.radius * 2 + comb.pad * 2
        width: comb.spanX
        height: comb.spanY

        anchors.centerIn: parent

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Theme.durationMedium } }
        Behavior on scale {
            NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutBack }
        }

        // Which cell the mouse is over, or applying, for the label under.
        property int hovered: -1

        Repeater {
            model: comb.pageCells

            delegate: Item {
                id: cellRoot

                // Plain JS-array models hand the delegate the context, which
                // is why nothing here asks for modelData.
                required property int index

                readonly property var cellData: comb.pageCells[index]
                readonly property real radius: comb.radius

                readonly property int row: Math.floor(cellRoot.index / comb.perRow)
                readonly property int col: cellRoot.index % comb.perRow

                readonly property bool current: comb.pickCurrent === cellRoot.cellData.path

                readonly property bool hovered: comb.hovered === cellRoot.index

                // The hexagon's own feet: centre, then the two half-widths.
                readonly property real cx: width / 2
                readonly property real cy: height / 2
                readonly property real rx: comb.side / 2
                readonly property real ry: comb.radius

                // Boxes are half a pad bigger than the hexagon, so the rim's
                // stroke never clips at the delegate's edge.
                width: comb.side + comb.pad * 2
                height: comb.radius * 2 + comb.pad * 2
                x: root.xFor(cellRoot)
                y: root.yFor(cellRoot)

                z: cellRoot.hovered || cellRoot.current ? 2 : 1
                scale: cellRoot.hovered ? 1.06 : 1.0

                Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic } }

                // The body carries the entrance, so the wave never fights
                // the hover: the wrapper lifts, the wax falls into place.
                Item {
                    id: body

                    anchors.fill: parent

                    Component.onCompleted: wave.restart()

                    // Wave + fade: each cell waits on its diagonal from the
                    // comb's head, then fades up with a whisper of scale.
                    // The thumbs for pages near this one are decoded ahead,
                    // so the wave never stutters on a disk read.
                    SequentialAnimation {
                        id: wave

                        running: false
                        PauseAnimation { duration: cellRoot.row * 35 + cellRoot.col * 18 }
                        ParallelAnimation {
                            NumberAnimation {
                                target: body
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 160
                            }
                            NumberAnimation {
                                target: body
                                property: "scale"
                                from: 0.86
                                to: 1
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                // The wax: the picture through the transition preview's own
                // route, texture into a ShapePath, six edges.
                ShaderEffectSource {
                    id: wax

                    sourceItem: picture
                    hideSource: true
                    live: true
                    visible: true
                    // Offstage: the texture pass runs regardless, but the
                    // surface is parked beyond the panel so its rectangle
                    // never falls on the hive.
                    x: 0
                    y: -4000
                    width: parent.width
                    height: parent.height
                }

                // The raw picture must not paint itself: the wax hides it
                // (hideSource) while sampling it — a rectangle of it lands
                // on the neighbours' corners otherwise.
                Image {
                    id: picture

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    // A cached thumb is small enough to decode on the spot:
                    // the pixel exists when the wave reaches its slot. An
                    // original the helper has not cut yet falls back to the
                    // asynchronous road.
                    asynchronous: root.thumbs[cellRoot.cellData.path] === undefined
                    // Thumbs read from the pre-cut cache; the wax for a
                    // motion cell is the blurred cut until a hover resolves
                    // it sharp. A wallpaper the helper has not reached yet
                    // shows the original.
                    source: {
                        const shown = cellRoot.cellData.motion
                            && cellRoot.cellData.poster !== ""
                            ? cellRoot.cellData.poster : cellRoot.cellData.path
                        const base = root.thumbs[shown]
                        const sharp = cellRoot.cellData.motion
                            && cellRoot.cellData.poster !== ""
                            ? root.thumbs["#:" + shown] : undefined
                        if (base === undefined)
                            return encodeURI("file://" + shown)
                        return cellRoot.hovered && sharp !== undefined
                            ? "file://" + sharp
                            : "file://" + base
                    }
                    sourceSize.width: Math.round(parent.width * 2)
                    sourceSize.height: Math.round(parent.height * 2)
                }

                Shape {
                    anchors.fill: parent

                    ShapePath {
                        // No rim: the wax says its shape on its own, and the
                        // fill reaches the path's edge exactly.
                        strokeWidth: -1
                        fillItem: cellRoot.cellData.motion
                            && cellRoot.cellData.poster === "" ? null : wax

                        PathPolyline {
                            path: [
                                Qt.point(cellRoot.cx, cellRoot.cy - cellRoot.ry),
                                Qt.point(cellRoot.cx + cellRoot.rx, cellRoot.cy - cellRoot.ry / 2),
                                Qt.point(cellRoot.cx + cellRoot.rx, cellRoot.cy + cellRoot.ry / 2),
                                Qt.point(cellRoot.cx, cellRoot.cy + cellRoot.ry),
                                Qt.point(cellRoot.cx - cellRoot.rx, cellRoot.cy + cellRoot.ry / 2),
                                Qt.point(cellRoot.cx - cellRoot.rx, cellRoot.cy - cellRoot.ry / 2),
                                Qt.point(cellRoot.cx, cellRoot.cy - cellRoot.ry)
                            ]
                        }
                    }
                }

                // What plays instead of sits: the cell is blurred at rest,
                // and a small sigil marks it — a play wedge in wax-white.
                Shape {
                    visible: cellRoot.cellData.motion
                    anchors.centerIn: parent
                    width: 46
                    height: 46

                    ShapePath {
                        fillColor: "#E6F4F7FB"

                        PathPolyline {
                            path: [
                                Qt.point(12, 7),
                                Qt.point(40, 23),
                                Qt.point(12, 39)
                            ]
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        comb.hovered = cellRoot.index
                        WallpaperService.apply(cellRoot.cellData.path)
                        // Choosing is doing: the hive closes itself.
                        root.closeDown()
                    }
                    onEntered: comb.hovered = cellRoot.index
                    // The wheel drifts the stack from anywhere on the hive.
                    onWheel: wheel => comb.turn(wheel.angleDelta.y < 0 ? 1 : -1)
                    }
                }
            }
        }
    }

    // The stack is rendered ahead: the pages a turn could land on hold
    // their thumbs decoded in the image cache, in the exact size the cells
    // ask for, so a page-turn's wave never waits on a disk read midflight.
    Item {
        visible: false

        Repeater {
            model: {
                const reach = [-1, 1, -2, 2]
                let near = []
                for (const step of reach) {
                    const at = comb.page + step
                    if (at >= 0 && at < comb.pages)
                        near = near.concat(comb.cells.slice(
                            at * comb.perPage, (at + 1) * comb.perPage)
                            .map(c => c.path))
                }
                return near
            }

            Image {
                asynchronous: true
                source: {
                    const small = root.thumbs[modelData]
                    return small !== undefined
                        ? "file://" + small : encodeURI("file://" + modelData)
                }
                sourceSize.width: Math.round((comb.side + comb.pad * 2) * 2)
                sourceSize.height: Math.round((comb.radius * 2 + comb.pad * 2) * 2)
            }
        }
    }

    // The comb's own coordinates: a cell's x is its column plus half a column
    // on every odd row, plus the pad; a shorter last row is centred, so the
    // page ends mid-comb instead of bleeding to the left edge.
    function xFor(cell: Item): real {
        const row = cell.row
        const inRow = Math.min(comb.perRow,
            comb.pageCells.length - row * comb.perRow)
        const shortOf = Math.max(0, comb.perRow - inRow)
        return comb.pad + shortOf * comb.side / 2
            + cell.col * comb.side + (row % 2) * comb.side / 2
    }

    function yFor(cell: Item): real {
        return comb.pad + cell.row * comb.radius * 1.5
    }

    Shortcut {
        enabled: root.open
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: root.closeDown()
    }

    // The hive also drifts on the arrows.
    Shortcut {
        enabled: root.open
        sequence: "Left"
        context: Qt.WindowShortcut
        onActivated: comb.turn(-1)
    }

    Shortcut {
        enabled: root.open
        sequence: "Right"
        context: Qt.WindowShortcut
        onActivated: comb.turn(1)
    }
}

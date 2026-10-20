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

    function toggle(): void {
        root.open ? root.closeDown() : root.openUp()
    }

    // No scan on boot; the first open asks for the folder.
    Component.onCompleted: {
        root.openChanged.connect(() => {
            if (root.open && comb.cells.length === 0)
                WallpaperService.scan()
        })
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
        onWheel: wheel => comb.turn(wheel.angleDelta.y > 0 ? 1 : -1)
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
        // page at a time and the wheel walks the stack. Twenty-one cells —
        // three staggered rows of seven — fit under the bar's airspace.
        property int page: 0
        readonly property int perPage: 21
        readonly property int pages: Math.max(1, Math.ceil(comb.cells.length / comb.perPage))
        readonly property var pageCells: comb.cells.slice(
            comb.page * comb.perPage, (comb.page + 1) * comb.perPage)

        function turn(drift: int): void {
            const at = comb.page + drift
            comb.page = Math.max(0, Math.min(comb.pages - 1, at))
        }

        // The desk's own picture, chosen or playing: the cell that matches
        // wears the accent.
        readonly property string pickCurrent: WallpaperService.chosen

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

                // The wax: the picture through the transition preview's own
                // route, texture into a ShapePath, six edges.
                ShaderEffectSource {
                    id: wax

                    sourceItem: picture
                    hideSource: true
                    live: true
                    visible: false
                }

                Image {
                    id: picture

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    source: encodeURI("file://" + (cellRoot.cellData.motion
                        ? (cellRoot.cellData.poster !== "" ? cellRoot.cellData.poster : "")
                        : cellRoot.cellData.path))
                    sourceSize.width: Math.round(parent.width * 2)
                    sourceSize.height: Math.round(parent.height * 2)
                }

                Shape {
                    anchors.fill: parent

                    ShapePath {
                        strokeWidth: cellRoot.current ? 2.5 : 1
                        strokeColor: cellRoot.current || cellRoot.hovered
                            ? Theme.accent : Theme.hairline
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

                // What plays instead of sits: a small ring at the apex.
                Text {
                    visible: cellRoot.cellData.motion
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    text: "󱅋"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeRegular
                    color: Theme.accentText
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        comb.hovered = cellRoot.index
                        WallpaperService.apply(cellRoot.cellData.path)
                    }
                    onEntered: comb.hovered = cellRoot.index
                    // The wheel drifts the stack from anywhere on the hive.
                    onWheel: wheel => comb.turn(wheel.angleDelta.y > 0 ? 1 : -1)
                }
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

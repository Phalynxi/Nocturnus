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

    function close(): void {
        root.open = false
    }

    function openUp(): void {
        if (!root.open)
            WallpaperService.scan()
        root.open = true
    }

    function toggle(): void {
        root.open ? root.close() : root.openUp()
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
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.open
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ── THE DARK ─────────────────────────────────────────────────────────────
    //
    // Everything under the scrim goes quiet; a click that lands nowhere on
    // the comb closes the hive. The ground reads like a fogged pane, not a
    // plain dim.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: root.open ? Qt.ArrowCursor : Qt.ArrowCursor
        onClicked: root.close()

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.island.r, Theme.island.g, Theme.island.b, 0.62)
        }
    }

    // ── THE COMB ─────────────────────────────────────────────────────────────
    //
    // Pointy-top hexagons: columns √3·R apart, rows 1.5·R, odd rows staggered
    // half a column. Six cells to a row; the comb centres itself.
    Item {
        id: comb

        readonly property real radius: 92
        readonly property int perRow: 6
        readonly property real side: root.radius * Math.sqrt(3)
        readonly property real pad: 4

        readonly property var stills: WallpaperService.wallpapers.map(path => ({
            path: path,
            poster: "",
            motion: false,
            name: String(path).split("/").pop().replace(/\.[^.]*$/, "")
        }))

        readonly property var moving: WallpaperService.animated.map(entry => ({
            path: entry.path,
            poster: entry.poster,
            motion: true,
            name: entry.name
        }))

        readonly property var cells: comb.stills.concat(comb.moving)

        // The desk's own picture, chosen or playing: the cell that matches
        // wears the accent.
        readonly property string pickCurrent: WallpaperService.chosen

        readonly property int rows: Math.max(1, Math.ceil(comb.cells.length / comb.perRow))
        readonly property real width: comb.perRow * comb.side + comb.pad * 2
            + (comb.rows > 1 ? comb.side / 2 : 0)
        readonly property real height: (comb.rows - 1) * comb.radius * 1.5
            + comb.radius * 2 + comb.pad * 2

        anchors.centerIn: parent

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Theme.durationMedium } }
        Behavior on scale {
            NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutBack }
        }

        // Which cell the mouse is over, or applying, for the label under.
        property int hovered: -1

        // ── WORDMARK ─────────────────────────────────────────────────────────
        //
        // Spaced caps above the comb, the count in mono under it. The hive
        // carries only what it selects; the bar keeps the time.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 30
            spacing: 3

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wallpapers".toUpperCase().split("").join(" ")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textMuted
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: `${comb.cells.length}`
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textMuted
            }
        }

        // The hovered or last-touched cell's name, spaced caps, below. One
        // line — no other words in the hive.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 28
            text: comb.cells[comb.hovered]?.name ?? ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.letterSpacing: 3
            color: Theme.text
        }

        Repeater {
            model: comb.cells

            delegate: Item {
                id: cellRoot

                // Plain JS-array models hand the delegate the context, which
                // is why nothing here asks for modelData.
                required property int index

                readonly property var cellData: comb.cells[index]
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
                x: comb.xFor(cellRoot)
                y: comb.yFor(cellRoot)

                z: cellRoot.hovered || cellRoot.current ? 2 : 1
                scale: cellRoot.hovered ? 1.06 : 1.0
                opacity: cellRoot.current ? 1 : (cellRoot.hovered ? 1 : 0.8)

                Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

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
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    source: cellRoot.cellData.motion
                        ? (cellRoot.cellData.poster !== "" ? `file://${cellRoot.cellData.poster}` : "")
                        : `file://${cellRoot.cellData.path}`
                    sourceSize.width: Math.round(parent.width * 2)
                    sourceSize.height: Math.round(parent.height * 2)
                }

                Shape {
                    anchors.fill: parent
                    layer.enabled: true

                    ShapePath {
                        strokeWidth: cellRoot.current ? 2.5 : 1
                        strokeStyle: ShapePath.Solid
                        strokeColor: cellRoot.current || cellRoot.hovered
                            ? Theme.accent : Theme.hairline
                        fillColor: "#00000000"
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
                }
            }
        }
    }

    // The comb's own coordinates: a cell's x is its column plus half a column
    // on every odd row, plus the pad that keeps strokes unclipped.
    function xFor(cell: Item): real {
        return comb.pad + cell.col * comb.side + (cell.row % 2) * comb.side / 2
    }

    function yFor(cell: Item): real {
        return comb.pad + cell.row * comb.radius * 1.5
    }

    Shortcut {
        enabled: root.open
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: root.close()
    }
}

// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P O S T E R   C L O C K                                                │
// │   the time as a poster's headline · straight on the wallpaper            │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

import "../../../theme"
import "../../../services"

// Five glyphs in the heaviest display weight, set so tight they overlap: the
// outer digits in the ink, the middle three in the accent, near opaque so
// the time holds on any picture, with just enough show-through that each
// overlap reads as a third tone. The date runs under it in spaced caps. No
// capsule (`DesktopService.bare`), so it reads the wallpaper under it
// (`scripts/luma.py`): on a light one it is set dark with a pale glow, on a
// dark one light with a heavy shadow.
Item {
    id: root

    property string family: "8x2"
    property var ink: DesktopService.inkFor(null)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string time: Qt.formatTime(clock.date, "HH:mm")

    // ── WHAT IS UNDER IT ────────────────────────────────────────────────────

    // Mean luminance of the wallpaper behind the face, 0 to 1.
    property real luma: 0
    readonly property bool onLight: root.luma > 0.55
    readonly property color outerInk: root.onLight ? "#1b1e23" : root.ink.text
    readonly property color middleInk: root.onLight
        ? Qt.darker(root.ink.accent, 1.25)
        : Qt.tint(root.ink.accent, Qt.rgba(1, 1, 1, 0.55))

    function probe(): void {
        const window = QsWindow.window
        if (!window || window.width <= 0 || !WallpaperService.currentWallpaper)
            return
        const at = root.mapToItem(null, 0, 0)
        probeProcess.command = [Quickshell.shellPath("scripts/luma.py"),
            WallpaperService.currentWallpaper,
            at.x / window.width, at.y / window.height,
            root.width / window.width, root.height / window.height,
            window.width, window.height]
        probeProcess.running = true
    }

    // Once things stop moving: a drag or a resize asks only at the end.
    Timer {
        id: reprobe
        interval: 400
        onTriggered: root.probe()
    }

    Process {
        id: probeProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(text.trim())
                if (text.trim() !== "" && !isNaN(value))
                    root.luma = value
            }
        }
    }

    Connections {
        target: WallpaperService
        function onCurrentWallpaperChanged(): void { reprobe.restart() }
    }

    Component.onCompleted: reprobe.restart()
    onXChanged: reprobe.restart()
    onYChanged: reprobe.restart()
    onWidthChanged: reprobe.restart()
    onHeightChanged: reprobe.restart()
    // The face sits still inside the widget, which is what moves.
    Connections {
        target: root.parent
        function onXChanged(): void { reprobe.restart() }
        function onYChanged(): void { reprobe.restart() }
    }

    // The headline fills the height left after the date line, and never
    // runs wider than the face.
    readonly property bool dated: root.family !== "4x2"
    readonly property real size: Math.min(
        (root.height - (root.dated ? 40 : 0)) * 1.05,
        root.width / 3.1)

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 1
        blurMax: 40
        shadowOpacity: root.onLight ? 0.7 : 0.9
        shadowVerticalOffset: root.onLight ? 0 : 3
        shadowColor: root.onLight ? "#ffffff" : "#000000"
    }

    // Set flush left, as a poster's headline is; the date hangs from the
    // same edge.
    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Row {
            // Tight enough that neighbours touch, and only just overlap.
            spacing: -root.size * 0.04

            Repeater {
                model: root.time.split("")

                Text {
                    required property string modelData
                    required property int index

                    readonly property bool outer: index === 0 || index === 4

                    text: modelData
                    textFormat: Text.PlainText
                    font.family: Theme.fontDisplay
                    font.pixelSize: root.size
                    font.weight: Font.Black
                    // Lifted so the colon sits in the digits' middle, not
                    // on their baseline.
                    topPadding: modelData === ":" ? -root.size * 0.06 : 0
                    color: outer ? root.outerInk : root.middleInk
                    opacity: outer ? 0.86 : 0.96

                    Behavior on color { ColorAnimation { duration: Theme.paletteTransition } }
                }
            }
        }

        Text {
            visible: root.dated
            // In from the edge by the digits' own side bearing.
            leftPadding: root.size * 0.05
            text: Qt.formatDate(clock.date, "dddd  ·  d MMMM").toUpperCase()
            textFormat: Text.PlainText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall + 2
            font.weight: Font.DemiBold
            font.letterSpacing: 4
            color: root.outerInk
            opacity: 0.92
        }
    }
}

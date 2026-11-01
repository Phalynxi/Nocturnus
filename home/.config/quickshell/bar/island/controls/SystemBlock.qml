// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S Y S T E M   B L O C K                                                │
// │   processor, memory, heat and the root disk · four rings                 │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../../theme"
import "../../../services"
import "../../../components"

// The machine at a glance: a ring each for the processor, memory, the
// hottest sensor and the root filesystem, the figure inside and the name
// under it. Two by two on a square, four in a row when wide. A click opens
// the statistics panel for the history behind them.
Card {
    id: root

    property int cols: 2
    property int rows: 2

    signal panelRequested(string panel)

    readonly property bool row: root.cols >= 2 * root.rows

    readonly property var rootDisk: (StatsService.disks ?? []).find(disk => disk.target === "/") ?? null
    readonly property real celsius: StatsService.temperature ? StatsService.temperature.celsius : 0

    readonly property var gauges: [
        { name: "CPU", value: StatsService.cpu / 100, figure: `${Math.round(StatsService.cpu)}%` },
        { name: "Memory", value: StatsService.memoryFraction, figure: `${Math.round(StatsService.memoryFraction * 100)}%` },
        { name: "Heat", value: root.celsius / 100, figure: StatsService.temperature ? `${Math.round(root.celsius)}°` : "—" },
        { name: "Disk", value: root.rootDisk ? root.rootDisk.used / root.rootDisk.total : 0,
          figure: root.rootDisk ? `${Math.round(100 * root.rootDisk.used / root.rootDisk.total)}%` : "—" }
    ]

    // A level past these reads as a warning, in the indicators' colours.
    function tint(gauge: var): color {
        if (gauge.value >= 0.9)
            return Theme.indicatorBad
        if (gauge.value >= 0.75)
            return Theme.indicatorWarn
        return Theme.accent
    }

    Grid {
        id: rings

        anchors.centerIn: parent
        columns: root.row ? 4 : 2
        columnSpacing: root.row ? 18 : 14
        rowSpacing: 10

        readonly property real ring: Math.max(28, Math.min(
            (root.width - 24 - (rings.columns - 1) * rings.columnSpacing) / rings.columns,
            (root.height - 24 - (root.row ? 0 : rings.rowSpacing)) / (root.row ? 1 : 2) - 18,
            54))

        Repeater {
            model: root.gauges

            Column {
                id: gauge

                required property var modelData

                spacing: 4

                RingIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: rings.ring
                    height: rings.ring
                    thickness: 3.5
                    progress: gauge.modelData.value
                    trackColor: Theme.indicatorDim
                    fillColor: root.tint(gauge.modelData)

                    Text {
                        anchors.centerIn: parent
                        text: gauge.modelData.figure
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(10, rings.ring * 0.24)
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: gauge.modelData.name
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLabel
                    color: Theme.textMuted
                }
            }
        }
    }

    TapHandler {
        cursorShape: Qt.PointingHandCursor
        onTapped: root.panelRequested("stats")
    }
}

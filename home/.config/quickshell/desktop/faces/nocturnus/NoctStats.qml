// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N   O   C   T   U   R   N   U   S   ·   S   T   A   T   S               │
// │   the machine as one strong figure and two hairlines                     │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../../theme"
import "../../../services"
import "../../../components"

// CPU as the figure — the display weight, filling the left — and memory and
// warmth as two hairlines on the right, each a spaced-caps label over four
// pixels of accent. On a 4×4 the three sit in a column with room between.
Item {
    id: root

    property string family: "4x2"
    property var ink: DesktopService.inkFor(null)

    readonly property string degree: StatsService.cpu.toFixed(0)

    // Warmth as fill: the reading in hundredths of a degree scale, held away
    // from the ends when the sensor says nothing.
    readonly property real warmth: StatsService.temperature
        ? Math.max(0, Math.min(1, StatsService.temperature.celsius / 100)) : 0

        // One row of the hairlines: a spaced-caps label and its reading, then a
        // thin bar of accentulated the fill. `fill` in 0…1.
        component Hairline: Column {
            id: line

            property string label: ""
            property string reading: ""
            property real fill: 0
            property color tone: root.ink.accent

            width: parent.width
            spacing: 6

            // An Item rather than a Row, so the reading can pin to the far
            // edge: anchors in a Row are refused.
            Item {
                width: parent.width
                height: Math.max(labelText.height, readingText.height)

                Text {
                    id: labelText
                    anchors.left: parent.left
                    text: line.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.letterSpacing: 2
                    color: root.ink.muted
                }

                Text {
                    id: readingText
                    anchors.right: parent.right
                    text: line.reading
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.ink.muted
                }
            }

            UsageBar {
                width: parent.width
                height: 4
                progress: line.fill
                fillColor: line.tone
                trackColor: root.ink.raised
            }
        }

    Row {
        visible: root.family !== "4x4"
        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        spacing: 22

        // The figure: the number and a small percent beside it, pinned to the
        // text baseline.
        Row {
            id: figure

            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                anchors.bottom: parent.bottom
                text: root.degree
                font.family: Theme.fontDisplay
                font.pixelSize: 46
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
                color: root.ink.text
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                text: "%"
                font.family: Theme.fontDisplay
                font.pixelSize: 17
                color: root.ink.accent
            }
        }

        // The hairlines: memory and warmth, said quietly beside the figure.
        Column {
            visible: root.family !== "4x4"
            width: parent.width - figure.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Hairline {
                label: "ram"
                reading: `${Math.round(StatsService.memoryFraction * 100)}%`
                fill: StatsService.memoryFraction
                width: parent.width
            }

            Hairline {
                label: "warmth"
                reading: StatsService.thermalWord
                fill: root.warmth
                width: parent.width
            }
        }
    }

    // 4×4: cpu, then memory and warmth each in their own room, matching the
    // bar with gaps so the face is read at a glance.
    Column {
        visible: root.family === "4x4"
        anchors.fill: parent
        anchors.margins: 26
        spacing: 18

        Row {
            width: parent.width
            spacing: 3

            Text {
                anchors.bottom: parent.bottom
                text: root.degree
                font.family: Theme.fontDisplay
                font.pixelSize: 46
                font.weight: Font.DemiBold
                textFormat: Text.PlainText
                color: root.ink.text
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                text: "% cpu"
                font.family: Theme.fontDisplay
                font.pixelSize: 17
                font.letterSpacing: 2
                color: root.ink.accent
            }
        }

        Hairline {
            label: "ram"
            reading: `${Math.round(StatsService.memoryFraction * 100)}%`
            fill: StatsService.memoryFraction
            width: parent.width
        }

        Hairline {
            label: "warmth"
            reading: StatsService.thermalWord
            fill: root.warmth
            width: parent.width
        }
    }
}

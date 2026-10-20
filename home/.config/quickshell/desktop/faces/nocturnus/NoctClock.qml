// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N   O   C   T   U   R   N   U   S   ·   C   L   O   C   K               │
// │   the hour as one strong figure on the glass                             │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../../theme"
import "../../../services"

// The time in the display weight, filling the pill; the date as spaced caps
// under it. Nothing else — the ground, the rim and the sheen are the
// widget's, and the face keeps its distance from both edges.
Item {
    id: root

    property string family: "4x2"
    property var ink: DesktopService.inkFor(null)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property bool wide: family !== "2x2"
    readonly property bool vast: family === "8x2" || family === "4x4"

    Column {
        anchors.centerIn: parent
        spacing: root.wide ? 10 : 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, Locale.ShortFormat)
            textFormat: Text.PlainText
            font.family: Theme.fontDisplay
            font.pixelSize: root.vast ? Theme.fontSizeDisplay * 0.9
                : root.wide ? Theme.fontSizeDisplay * 0.68 : 38
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            color: root.ink.text
        }

        Row {
            visible: root.wide
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            // One accent dot holds the date to the time — the only colour on
            // the pill beyond the type.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                height: 4
                radius: 2
                color: root.ink.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(clock.date, "ddd  d MMM").toUpperCase()
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.letterSpacing: 3
                color: root.ink.muted
            }
        }
    }
}

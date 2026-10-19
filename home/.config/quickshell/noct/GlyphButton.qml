// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   G L Y P H   B U T T O N                                                │
// │   a nerd-font glyph in a hoverable disc · the bar's buttons               │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import "../theme"

Rectangle {
    id: root

    property string glyph: ""
    property string tip: ""
    property bool dimmed: false

    signal clicked()

    width: 28
    height: 28
    radius: 14
    color: mouse.containsMouse ? Theme.islandSurfaceHover : "transparent"

    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: Theme.fontMono
        font.pixelSize: 15
        color: root.dimmed ? Theme.indicatorDim
            : mouse.containsMouse ? Theme.text : Theme.textMuted
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

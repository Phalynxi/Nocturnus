// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C A R O U S E L   T I L E                                              │
// │   carousel tile · position and scale from distance to the selected one   │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

// A `Carousel` delegate: position, size and selected state come from the
// parent strip. Content is laid out once at rest size and scaled up when
// selected. The scale is around the tile's own centre, so an enlarged tile
// never leans out of the strip.
Item {
    id: root

    required property int index
    required property var modelData

    readonly property var strip: root.parent

    readonly property real distance: root.index - root.strip.position
    readonly property bool centred: root.index === root.strip.current
    readonly property bool hovered: mouse.containsMouse

    width: root.strip.tileWidth
    height: root.strip.tileHeight
    x: root.strip.offset + root.index * root.strip.stride
    // Centre the scaled tile, not the rest-size box, so the enlargement is
    // symmetric and the strip only has to be as tall as the scaled tile.
    y: (root.strip.height - root.height * root.scale) / 2
    scale: root.strip.scaleOf(root.distance)
    transformOrigin: Item.Center
    visible: root.x + root.width > -root.strip.inset
        && root.x < root.strip.width + root.strip.inset
    // Tiles nearer the selected one stack on top, so a sliding neighbour never
    // overlaps it.
    z: -Math.abs(root.distance)

    MouseArea {
        id: mouse

        anchors.fill: parent
        z: 1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.strip.press(root.index)
    }
}

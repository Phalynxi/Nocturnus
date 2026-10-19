// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C A R O U S E L                                                        │
// │   horizontal carousel · the selected tile enlarged, filling from the left │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../theme"

// A horizontal strip of tiles with the selected one enlarged.
//
// Tiles are laid out left to right at a fixed stride and the strip scrolls to
// hold the selected one: centred once there is room on both sides, filling
// from the left edge at the start and to the right edge at the end. Only
// `position` animates; each tile derives its offset and scale from its
// distance to it, so a step is one animation and a held arrow key retargets
// it instead of queueing. Delegates are `CarouselTile`s, which read the
// geometry through `parent`.
Item {
    id: root

    property alias model: repeater.model
    property alias delegate: repeater.delegate

    property int current: 0
    readonly property int count: repeater.count

    property int tileWidth: 160
    property int tileHeight: 100
    property real centreScale: 1.25
    property int gap: 12

    // The selected tile was clicked, or Enter was pressed.
    signal activated(int index)

    // Fractional while sliding.
    property real position: root.current

    Behavior on position {
        NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing }
    }

    implicitHeight: Math.ceil(root.tileHeight * root.centreScale)
    clip: true

    // Tiles sit one stride apart; the content is as wide as all of them.
    readonly property real stride: root.tileWidth + root.gap
    readonly property real contentWidth: root.count > 0
        ? (root.count - 1) * root.stride + root.tileWidth : 0

    // The enlarged tile reaches this far past its own edges, so the strip
    // insets by it and a centred tile is never clipped at the sides.
    readonly property real inset: root.tileWidth * (root.centreScale - 1) / 2

    // How far the content is shifted: the selected tile centred, clamped so
    // the strip fills from the left edge at the start and to the right edge at
    // the end. Narrower content than the strip is centred as a whole.
    readonly property real offset: {
        if (root.count === 0 || root.width <= 0)
            return 0
        const selectedCentre = root.position * root.stride + root.tileWidth / 2
        const centred = root.width / 2 - selectedCentre
        if (root.contentWidth + 2 * root.inset <= root.width)
            return (root.width - root.contentWidth) / 2
        const minOffset = root.width - root.contentWidth - root.inset
        return Math.max(minOffset, Math.min(root.inset, centred))
    }

    function scaleOf(distance: real): real {
        return 1 + (root.centreScale - 1) * Math.max(0, 1 - Math.abs(distance))
    }

    function goTo(index: int): void {
        if (root.count === 0)
            return
        root.current = Math.max(0, Math.min(root.count - 1, index))
    }

    function step(delta: int): void {
        root.goTo(root.current + delta)
    }

    // Clicking the selected tile activates it; any other tile scrolls to it.
    function press(index: int): void {
        if (index === root.current)
            root.activated(index)
        else
            root.goTo(index)
    }

    Repeater { id: repeater }

    // Touchpads send many small deltas; accumulate them to one step per 120.
    WheelHandler {
        property real turned: 0

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y
            turned += delta
            while (Math.abs(turned) >= 120) {
                root.step(turned < 0 ? 1 : -1)
                turned -= 120 * Math.sign(turned)
            }
        }
    }
}

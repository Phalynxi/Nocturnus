// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P I L L                                                                │
// │   a capsule with no edge · its rim is only a soft shadow                 │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Effects
import "../theme"

Rectangle {
    id: pill

    default property alias content: content.data

    // The island's ground, glassy whatever the style says; the hard border
    // is gone. What marks the edge instead: the shadow beneath.
    color: Theme.islandGround
    radius: height / 2

    // A black copy of the shape, blurred inside its own layer. The blur
    // never sees the pill's contents, so a ticking clock or a spectrum
    // repaints nothing in the shadow pass.
    Item {
        anchors.fill: parent
        anchors.margins: -16
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 32
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 18
            anchors.bottomMargin: 14
            radius: pill.height / 2
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }

    Item {
        id: content
        anchors.fill: parent
    }
}

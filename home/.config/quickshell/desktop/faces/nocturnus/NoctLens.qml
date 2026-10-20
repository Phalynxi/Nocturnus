// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N   O   C   T   U   R   N   U   S   ·   L   E   N   S                   │
// │   the quiet face, for modules not yet drawn                              │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../../theme"
import "../../../services"
import "../../../components"
import "."

// A module drawn before a face exists for it: one dimmed glyph on a wide,
// the module's name in spaced caps under it. It is honest — nothing is
// claimed but the module's presence — and every lamp drawn one day replaces
// an entry in `faces/Nocturnus.qml`.
Item {
    id: root

    property string moduleId: ""
    property string family: "4x2"
    property var ink: DesktopService.inkFor(null)

    readonly property var table: ({
        media:      ["󰝚", "media"],
        clock:      ["󰥔", "clock"],
        stats:      ["󰓅", "stats"],
        timer:      ["󱎫", "timer"],
        battery:    ["󰁹", "battery"],
        volume:     ["󰕾", "volume"],
        brightness: ["󰃟", "brightness"],
        network:    ["󰛳", "network"],
        bluetooth:  ["󰂯", "bluetooth"],
        weather:    ["󰖟", "weather"],
        github:     ["󰊤", "github"],
        updates:    ["󰬛", "updates"],
        pet:        ["󰽏", "pet"],
        games:      ["󰊴", "games"],
        claude:     ["󱚤", "claude"],
        codex:      ["󱚠", "codex"],
        calendar:   ["󰃭", "calendar"],
        tasks:      ["󰄱", "tasks"],
        notes:      ["󰎙", "notes"],
        photo:      ["󰉉", "photo"],
        spectrum:   ["󰐾", "spectrum"]
    })

    readonly property var lamp: table[moduleId] ? table[moduleId] : ["󰍛", moduleId]
    readonly property bool square: family === "2x2"
    readonly property bool vast: family === "8x2" || family === "4x4"

    Column {
        anchors.centerIn: parent
        spacing: root.square ? 6 : 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.lamp[0]
            font.family: Theme.fontMono
            font.pixelSize: root.vast ? Theme.fontSizeWidget * 1.3
                : root.square ? Theme.fontSizeWidget * 0.9 : Theme.fontSizeWidget * 1.1
            color: root.ink.muted
        }

        Text {
            visible: root.square
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.lamp[1].toUpperCase()
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.letterSpacing: 2
            color: root.ink.muted
        }
    }
}

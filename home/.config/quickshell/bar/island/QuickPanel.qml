// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   Q U I C K   P A N E L                                                  │
// │   the island's drawer · a row of buttons pulled down from the handle     │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../../theme"
import "../../services"
import "../../components"

// The drawer's buttons (`Bar.qml`), opened from the line under the island
// or the control-centre key: one row of round buttons: mute and deafen, which hold their state and are lit red while
// on, and the settings. The session menu has its own key. Also the island's
// panel for anything still asking it for "controls"
// (`DynamicIsland.panelSizes`).
Item {
    id: root

    signal closed()
    signal panelRequested(string panel)
    signal settingsRequested()

    readonly property var actions: [
        { icon: AudioService.sourceMuted ? "󰍭" : "󰍬", label: "Mute",
          on: AudioService.sourceMuted, act: () => AudioService.toggleSourceMute() },
        { icon: AudioService.muted ? "󰖁" : "󰕾", label: "Deafen",
          on: AudioService.muted, act: () => AudioService.toggleMute() },
        { icon: "󰒓", label: "Settings", on: false,
          act: () => root.settingsRequested() }
    ]

    // One slot per button, all the same width, so the row is centred
    // whatever its labels measure.
    readonly property int slot: 64
    readonly property int minimumWidth: root.actions.length * root.slot

    implicitWidth: root.minimumWidth
    implicitHeight: 40 + 5 + 14

    Row {
        anchors.fill: parent

        Repeater {
            model: root.actions

            Item {
                id: action

                required property var modelData

                width: root.width / root.actions.length
                height: root.height

                Rectangle {
                    id: button

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: action.modelData.on
                        ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.85)
                        : hover.hovered ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
                    border.color: action.modelData.on ? "transparent" : Theme.borderIn(QsWindow.window)
                    border.width: 1
                    scale: tap.pressed ? 0.92 : 1

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }

                    // Filling the circle and aligned in it: a nerd-font glyph's own
                    // box is not centred on its drawing, so centring the box
                    // leaves the icon off.
                    Text {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: action.modelData.icon
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                        color: action.modelData.on ? "#ffffff" : Theme.text
                    }

                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

                    TapHandler {
                        id: tap
                        onTapped: {
                            if (action.modelData.closes)
                                root.closed()
                            action.modelData.act()
                        }
                    }
                }

                Text {
                    anchors.top: button.bottom
                    anchors.topMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: action.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLabel + 1
                    color: action.modelData.on ? Theme.text : Theme.textMuted
                }
            }
        }
    }
}

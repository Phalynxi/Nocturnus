// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R                                                                  │
// │   a row of pills · workspaces, the clock, and the tray                   │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"
import "../theme"

PanelWindow {
    id: root

    signal launcherRequested()
    signal wallpapersRequested()

    // Named for the blur behind it, which shows only through a ground that
    // is not solid (windowrules.lua / CompositorService layer rules).
    WlrLayershell.namespace: "nocturnus-bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 8
        left: 12
        right: 12
    }

    // The pills' row: one capsule blend reserved for windows.
    readonly property int barHeight: Theme.capsuleHeight
    implicitHeight: root.barHeight + 4
    exclusiveZone: root.barHeight + 12
    color: "transparent"

    readonly property string screenName: Quickshell.screens.length > 0
        ? Quickshell.screens[0].name : ""
    readonly property int activeWs: root.screenName !== ""
        ? HyprlandService.activeOn(root.screenName) : 1

    // ── left · workspaces ────────────────────────────────────────────────────

    Pill {
        id: workspacesPill

        x: 0
        y: 2
        height: root.barHeight - 4
        width: workspacesRow.width + 28

        Row {
            id: workspacesRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: Math.min(HyprlandService.slots, 9)

                delegate: Rectangle {
                    id: ws

                    readonly property int id: index + 1
                    readonly property bool isActive: id === root.activeWs
                    readonly property bool occupied: HyprlandService.isOccupied(id)

                    width: isActive ? 32 : 26
                    height: 26
                    radius: 13
                    color: isActive ? Theme.accent
                        : mouse.containsMouse ? Theme.islandSurfaceHover : "transparent"

                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: parent.id
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: parent.isActive ? Theme.accentText
                            : parent.occupied ? Theme.text : Theme.textMuted
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: HyprlandService.focus(parent.id)
                    }
                }
            }
        }
    }

    // ── centre · what is playing and the clock ───────────────────────────────

    Pill {
        id: centrePill

        anchors.horizontalCenter: parent.horizontalCenter
        y: 2
        height: root.barHeight - 4
        width: centre.width + 32

        Item {
            id: hub

            anchors.centerIn: parent
            width: centre.width
            height: parent.height

            readonly property var moment: new Date()
            readonly property string title: MediaService.available && MediaService.title !== ""
                ? MediaService.title : ""

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Timer {
                interval: 30000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: hub.moment = new Date()
            }

            Row {
                id: centre
                anchors.centerIn: parent
                spacing: 10

                Text {
                    visible: hub.title !== ""
                    text: MediaService.playing ? "󰎈" : "󰏤"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: hub.title !== ""
                    text: hub.title
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 260)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: hub.title !== ""
                    text: "·"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.indicatorDim
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Theme.text
                    text: {
                        const pad = h => String(h).padStart(2, "0")
                        return pad(hub.moment.getHours()) + ":" + pad(hub.moment.getMinutes())
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "·"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.indicatorDim
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                    text: Qt.formatDate(hub.moment, "ddd d MMM")
                }
            }
        }
    }

    // ── right · tray, net, sound, battery, buttons ───────────────────────────

    Pill {
        id: rightPill

        anchors.right: parent.right
        y: 2
        height: root.barHeight - 4
        width: status.width + 24

        Row {
            id: status
            anchors.centerIn: parent
            spacing: 6

            // tray icons, drawn dim for the dark bar
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                visible: TrayService.items.length > 0

                Repeater {
                    model: TrayService.items

                    delegate: TrayIcon {
                        readonly property var modelData: TrayService.items[index]
                        icon: modelData?.icon ?? ""
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.85
                    }
                }
            }

            GlyphButton {
                glyph: NetworkService.icon
                tip: NetworkService.connectionName
            }

            GlyphButton {
                glyph: AudioService.icon
                dimmed: AudioService.muted
                tip: "Volume " + AudioService.volume + "%"
                onClicked: {
                    if (AudioService.ready)
                        AudioService.sink.audio.muted = !AudioService.muted
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                visible: BatteryService.available

                Text {
                    text: {
                        const index = BatteryService.charging ? 10
                            : Math.max(0, Math.min(9, 9 - Math.floor(BatteryService.percent / 10)))
                        return BatteryService.levelIcons[index]
                    }
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: BatteryService.charging || BatteryService.full
                        ? Theme.indicatorGood
                        : BatteryService.low ? Theme.indicatorWarn : Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: BatteryService.percent + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            GlyphButton {
                glyph: "󰀻"
                tip: "Launcher"
                onClicked: root.launcherRequested()
            }

            GlyphButton {
                glyph: "󰸉"
                tip: "Wallpapers"
                onClicked: root.wallpapersRequested()
            }
        }
    }
}

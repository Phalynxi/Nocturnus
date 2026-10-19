// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   B A R                                                                  │
// │   a full-width capsule · workspaces, clock, media and the tray           │
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

    implicitHeight: 48
    // 48 of capsule plus the 8px margin above it, so windows tuck under.
    exclusiveZone: 56
    color: "transparent"

    // report
    readonly property string screenName: Quickshell.screens.length > 0
        ? Quickshell.screens[0].name : ""
    readonly property int activeWs: root.screenName !== ""
        ? HyprlandService.activeOn(root.screenName) : 1

    Rectangle {
        id: capsule

        anchors.fill: parent
        radius: 24
        color: Theme.islandGround
        border.width: Theme.glass ? 1 : 0
        border.color: Theme.islandBorder

        // ── left · workspaces ────────────────────────────────────────────────

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: Math.min(HyprlandService.slots, 9)

                delegate: Rectangle {
                    id: ws

                    readonly property int id: index + 1
                    readonly property bool isActive: id === root.activeWs
                    readonly property bool occupied: HyprlandService.isOccupied(id)

                    width: isActive ? 32 : height
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

        // ── centre · clock and what is playing ───────────────────────────────

        Item {
            id: hub

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: centre.width
            height: 30

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
                    visible: parent.parent.title !== ""
                    text: MediaService.playing ? "󰎈" : "󰏤"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: Theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: parent.parent.title !== ""
                    text: parent.parent.title
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, 260)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: parent.parent.title !== ""
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
                        return pad(parent.parent.moment.getHours()) + ":" + pad(parent.parent.moment.getMinutes())
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
                    text: Qt.formatDate(parent.parent.moment, "ddd d MMM")
                }
            }
        }

        // ── right · tray, net, sound, battery, buttons ───────────────────────

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
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

    // input only inside the capsule: the gutters pass clicks through
    mask: Region {
        item: capsule
    }
}

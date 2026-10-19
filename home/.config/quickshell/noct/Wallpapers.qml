// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   W A L L P A P E R S                                                    │
// │   a grid over a dimmed desk · pick and the palette follows               │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"
import "../theme"

PanelWindow {
    id: root

    property bool open: false
    readonly property bool shown: open

    function show(): void {
        WallpaperService.scan()
        root.open = true
    }

    function close(): void {
        root.open = false
    }

    function toggle(): void {
        root.open ? root.close() : root.show()
    }

    WlrLayershell.namespace: "nocturnus-wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    visible: root.open && WallpaperService.wallpapers.length > 0
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.open ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    TapHandler {
        onTapped: root.close()
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: Math.min(parent.width - 160, 6 * 250)
        height: 470
        radius: 20
        color: Theme.islandSurface
        border.width: 1
        border.color: Theme.islandBorder

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Item {
                width: parent.width
                height: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wallpapers · " + WallpaperService.wallpapers.length
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Theme.text
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "click a picture to set it · click elsewhere to close"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textMuted
                }
            }

            GridView {
                id: grid

                width: parent.width
                height: parent.height - 24 - parent.spacing
                clip: true

                cellWidth: Math.floor(width / 3)
                cellHeight: cellWidth * 9 / 16 + 8

                model: WallpaperService.wallpapers
                reuseItems: true
                cacheBuffer: 400

                Component.onCompleted: {
                    if (WallpaperService.wallpapers.length === 0)
                        WallpaperService.scan()
                }

                delegate: Item {
                    id: cell

                    readonly property var modelData: grid.model[index]
                    readonly property string path: modelData?.path ?? ""
                    readonly property bool current:
                        path !== "" && path === WallpaperService.currentWallpaper

                    anchors.margins: 6

                    Rectangle {
                        id: tile

                        anchors.fill: parent
                        anchors.rightMargin: 8
                        anchors.bottomMargin: 8
                        radius: 10
                        color: Theme.islandSurfaceHover
                        clip: true
                        border.width: cell.current ? 2 : 1
                        border.color: cell.current ? Theme.accent : Theme.islandBorder

                        Behavior on border.width { NumberAnimation { duration: 100 } }

                        Image {
                            id: shot
                            anchors.fill: parent
                            visible: path.match(/\.(png|jpe?g|webp)$/i) !== null
                            anchors.margins: 0
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            source: path !== "" ? "file://" + path : ""
                            opacity: mouse.containsMouse
                                || cell.current ? 1 : 0.82
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            cache: true
                        }

                        Text {
                            visible: !shot.visible
                            anchors.centerIn: parent
                            text: "󰩅"
                            font.family: Theme.fontMono
                            font.pixelSize: 24
                            color: Theme.textMuted
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.apply(cell.path)
                        }
                    }
                }
            }
        }
    }
}

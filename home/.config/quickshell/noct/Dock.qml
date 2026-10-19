// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   D O C K                                                                │
// │   a capsule at the bottom · pinned and running applications              │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../dock"
import "../services"
import "../theme"

PanelWindow {
    id: root

    signal launcherRequested()

    WlrLayershell.namespace: "nocturnus-dock"
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins.bottom: 10
    implicitHeight: 62
    exclusiveZone: -1
    color: "transparent"

    Rectangle {
        id: shelf

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: row.width + 24
        height: row.height
        radius: height / 2
        color: Theme.dockGroundOf(Theme.dockStyle)

        // the shadow instead of an edge, same as the bar's pills
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
                anchors.topMargin: 0
                anchors.bottomMargin: 12
                radius: parent.height / 2
                color: Qt.rgba(0, 0, 0, 0.5)
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.dockGap

            // the launcher mark, docked to the left of the applications
            Rectangle {
                visible: DockService.hasLauncher
                width: 40
                height: 40
                radius: 20
                color: launchMouse.containsMouse ? Theme.islandSurfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰀻"
                    font.family: Theme.fontMono
                    font.pixelSize: 18
                    color: launchMouse.containsMouse ? Theme.text : Theme.textMuted
                }

                MouseArea {
                    id: launchMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launcherRequested()
                }
            }

            Rectangle {
                visible: DockService.hasLauncher && DockService.count > 0
                width: 1
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.hairline
            }

            Repeater {
                model: ScriptModel {
                    values: DockService.items
                    objectProp: "key"
                }

                DockItem {
                    capsule: shelf
                }
            }
        }
    }

    mask: Region {
        item: shelf
    }
}

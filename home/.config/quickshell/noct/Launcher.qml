// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L A U N C H E R                                                        │
// │   a card over a dimmed desk · search and go                              │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../services"
import "../theme"

PanelWindow {
    id: root

    readonly property bool shown: open
    property bool open: false

    function show(): void {
        field.text = ""
        root.open = true
        field.forceActiveFocus()
    }

    function close(): void {
        root.open = false
        field.text = ""
    }

    function toggle(): void {
        root.open ? root.close() : root.show()
    }

    // ── the list ─────────────────────────────────────────────────────────────

    readonly property var results: LauncherService.results
    property int selected: 0

    onResultsChanged: root.selected = 0
    onOpenChanged: root.selected = 0

    function move(step: int): void {
        const count = root.results.length
        if (count === 0)
            return
        root.selected = (root.selected + step + count) % count
    }

    function accept(): void {
        const entry = root.results[root.selected]
        if (entry === undefined || entry === null)
            return
        if (typeof entry.id === "string" && entry.id.endsWith(".desktop")) {
            LauncherService.launchDesktop(entry.id)
            root.close()
        }
    }

    WlrLayershell.namespace: "nocturnus-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    visible: root.open
    color: "transparent"

    // the desk dims behind the card
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.open ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    // click anywhere outside the card to leave
    TapHandler {
        onTapped: root.close()
    }

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(60, (parent.height / 2) - 220)
        width: 560
        height: fieldPanel.height + (list.count > 0 ? list.height + 4 : 0) + 14
        radius: 18
        color: Theme.islandSurface
        border.width: 1
        border.color: Theme.islandBorder

        Rectangle {
            id: fieldPanel

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6
            height: 44
            radius: 13
            color: Theme.islandSurfaceHover

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: LauncherService.modeFor(field.text).icon
                visible: field.text === ""
                font.family: Theme.fontMono
                font.pixelSize: 15
                color: Theme.textMuted
            }

            TextField {
                id: field

                anchors.fill: parent
                anchors.leftMargin: LauncherService.modeFor(text).prefix === "" ? 38 : 32
                background: null
                font.family: Theme.fontMono
                font.pixelSize: 14
                color: Theme.text
                placeholderText: LauncherService.modeFor(text).hint
                placeholderTextColor: Theme.textMuted
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true

                onTextChanged: LauncherService.query = text

                Keys.onEscapePressed: root.close()
                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
                Keys.onDownPressed: root.move(1)
                Keys.onUpPressed: root.move(-1)
            }
        }

        ListView {
            id: list

            anchors.top: fieldPanel.bottom
            anchors.topMargin: 4
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            height: Math.min(count * 42, 400)
            clip: true
            interactive: false
            model: root.results
            currentIndex: root.selected
            cacheBuffer: 80

            reuseItems: true

            delegate: Rectangle {
                id: entry

                readonly property var modelData: root.results[index]
                readonly property bool chosen: index === root.selected

                width: list.width
                height: 42
                radius: 10
                color: chosen ? Theme.islandSurfaceHover : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Image {
                    id: picture

                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    source: entry.modelData.icon !== ""
                        ? Quickshell.iconPath(entry.modelData.icon, true) : ""
                    visible: entry.modelData.icon !== "" && (entry.modelData.kind ?? "") === "app"
                }

                Text {
                    visible: picture.source === ""
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.icon !== "" ? entry.modelData.icon : "󰀻"
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: Theme.textMuted
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 50
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.name ?? String(entry.modelData)
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: entry.chosen ? Theme.text : Theme.textMuted
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    visible: (entry.modelData.subtitle ?? "") !== ""
                    anchors.left: parent.left
                    anchors.leftMargin: 240
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.subtitle ?? ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.indicatorDim
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = entry.index
                    onClicked: root.accept()
                }
            }
        }
    }
}

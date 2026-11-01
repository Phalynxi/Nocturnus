// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L A U N C H E R                                                        │
// │   its own surface · one card in the island's glass                       │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../theme"
import "../services"
import "../components"

// The launcher, apart from the island: a full-screen layer on the screen
// being worked on, holding one card in the island's glass.
//
//   empty query    the applications used most, as a grid of large icons
//   typing         the matches as a list, the chosen one lit
//   footer         the modes as chips (calculate, windows, clipboard…)
//
// Search, ranking and what a row does are `LauncherService`'s; this is only
// how it looks and how the keys move through it. Arrows, Tab and Enter;
// Escape clears the field first and closes once it is empty.
PanelWindow {
    id: root

    property bool open: false

    function toggle(): void {
        root.open ? root.close() : root.show("")
    }

    // Opens on a mode's sigil, or closes when that mode is already showing.
    function show(sigil: string): void {
        if (root.open && sigil !== "" && LauncherService.query.startsWith(sigil)) {
            root.close()
            return
        }
        LauncherService.query = sigil
        root.selected = 0
        root.open = true
        field.forceActiveFocus()
    }

    function close(): void {
        root.open = false
        LauncherService.query = ""
    }

    // The screen being worked on.
    screen: Quickshell.screens.find(output => output.name === HyprlandService.focusedMonitor)
        ?? Quickshell.screens[0]

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: root.open || card.opacity > 0

    // The bar's material, so every row, chip and edge here is the same tint
    // as on the island.
    readonly property bool glassy: true
    readonly property string groundStyle: Theme.surfaceStyle

    WlrLayershell.namespace: "nocturnus-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ── WHAT IS SHOWN ───────────────────────────────────────────────────────

    readonly property var mode: LauncherService.modeFor(LauncherService.query)
    readonly property bool idle: LauncherService.query === ""
    // Empty, the most used applications; otherwise the service's matches.
    readonly property var entries: root.idle
        ? LauncherService.rank("").slice(0, root.columns * 2)
        : LauncherService.results

    readonly property int columns: 6
    property int selected: 0

    // The field holds the query without its sigil, which the chip shows. Set
    // only when the query changes from outside (a chip, a mode key, a sigil
    // just typed), so typing is never rewritten under the cursor.
    Connections {
        target: LauncherService

        function onQueryChanged(): void {
            const term = LauncherService.query.slice(root.mode.prefix.length)
            if (field.text !== term)
                field.text = term
        }
    }

    onEntriesChanged: root.selected = 0

    function move(by: int): void {
        if (root.entries.length === 0)
            return
        root.selected = Math.max(0, Math.min(root.entries.length - 1, root.selected + by))
        if (!root.idle)
            list.positionViewAtIndex(root.selected, ListView.Contain)
    }

    // Panels and settings go to the shell, a mode row switches the field,
    // everything else the service runs and the launcher closes.
    function run(entry: var): void {
        if (!entry)
            return
        if (entry.kind === "mode") {
            LauncherService.query = entry.sigil
            field.forceActiveFocus()
            return
        }
        root.close()
        if (entry.kind === "panel") {
            if (entry.panel === "")
                ModuleService.settingsRequested()
            else
                ModuleService.requestPanel(entry.panel)
            return
        }
        LauncherService.activate(entry)
    }

    function tint(kind: string): color {
        switch (kind) {
        case "calculation": return Theme.green
        case "action": return Theme.yellow
        case "timer":
        case "window":
        case "minimized": return Theme.blue
        default: return Theme.accent
        }
    }

    // ── OUTSIDE ─────────────────────────────────────────────────────────────
    //
    // Nothing drawn round the card: the screen stays as it is, as it does
    // round the settings window. A click anywhere off the card closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // ── CARD ────────────────────────────────────────────────────────────────

    Rectangle {
        id: card

        readonly property int inner: 680

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.18) + (root.open ? 0 : 14)
        width: card.inner
        height: column.implicitHeight + 28
        radius: 26
        // The island's ground: the same glass over the compositor's lens.
        color: Theme.islandGround
        border.color: Theme.islandRim
        border.width: Theme.glass ? 0 : 1
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.97

        Behavior on y { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }
        Behavior on opacity { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing } }
        Behavior on height { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing } }

        // Clicks on the card stay on it.
        MouseArea { anchors.fill: parent }

        // The island's light along the top and its thick edge.
        GlassSheen {
            shape: card
            visible: Theme.glass
        }

        ColumnLayout {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            // ── FIELD ───────────────────────────────────────────────────────

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 12

                // The mode's glyph; the magnifier for applications.
                Text {
                    text: root.mode.icon
                    font.family: Theme.fontMono
                    font.pixelSize: 22
                    color: root.mode.id === "apps" ? Theme.textMuted : Theme.text
                }

                // The mode, as a chip, once a sigil has been typed.
                Rectangle {
                    visible: root.mode.id !== "apps"
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: chipLabel.implicitWidth + 20
                    radius: 14
                    color: Theme.surfaceHoverIn(root)
                    border.color: Theme.borderIn(root)

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: root.mode.label
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall + 1
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }
                }

                TextInput {
                    id: field

                    Layout.fillWidth: true
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    color: Theme.text
                    selectByMouse: true
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    clip: true
                    focus: root.open

                    onTextEdited: {
                        // A sigil typed into the empty field picks its mode.
                        const typed = root.mode.prefix + field.text
                        LauncherService.query = root.mode.id === "apps" ? field.text : typed
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text === ""
                        text: root.mode.id === "apps" ? Tr.t("Search apps, or type a sigil") : Tr.t(root.mode.hint)
                        font: field.font
                        color: Theme.textMuted
                    }

                    Keys.onPressed: event => {
                        const grid = root.idle
                        if (event.key === Qt.Key_Escape) {
                            if (LauncherService.query !== "")
                                LauncherService.query = ""
                            else
                                root.close()
                        } else if (event.key === Qt.Key_Backspace && field.text === "" && root.mode.id !== "apps") {
                            // Backspace on an empty field leaves the mode.
                            LauncherService.query = ""
                        } else if (event.key === Qt.Key_Down) {
                            root.move(grid ? root.columns : 1)
                        } else if (event.key === Qt.Key_Up) {
                            root.move(grid ? -root.columns : -1)
                        } else if (grid && event.key === Qt.Key_Right && field.text === "") {
                            root.move(1)
                        } else if (grid && event.key === Qt.Key_Left && field.text === "") {
                            root.move(-1)
                        } else if (event.key === Qt.Key_Tab) {
                            root.move(1)
                        } else if (event.key === Qt.Key_Backtab) {
                            root.move(-1)
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.run(root.entries[root.selected])
                        } else {
                            return
                        }
                        event.accepted = true
                    }
                }

                Text {
                    text: "esc"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeLabel
                    color: Theme.textMuted
                    opacity: 0.7
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.borderIn(root)
            }

            // ── GRID ────────────────────────────────────────────────────────
            //
            // The applications used most, while nothing is typed.
            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.idle
                columns: root.columns
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: root.idle ? root.entries : []

                    Rectangle {
                        id: tile

                        required property var modelData
                        required property int index

                        readonly property bool chosen: tile.index === root.selected

                        Layout.fillWidth: true
                        Layout.preferredHeight: 104
                        radius: 18
                        color: tile.chosen ? Theme.surfaceHoverIn(root)
                            : tileHover.hovered ? Theme.surfaceIn(root) : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 52
                                height: 52
                                sourceSize.width: 104
                                sourceSize.height: 104
                                source: tile.modelData.icon ? Quickshell.iconPath(tile.modelData.icon, true) : ""
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: tile.width - 12
                                horizontalAlignment: Text.AlignHCenter
                                text: tile.modelData.name
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall + 1
                                color: tile.chosen ? Theme.text : Theme.textMuted
                            }
                        }

                        HoverHandler {
                            id: tileHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: if (hovered) root.selected = tile.index
                        }
                        TapHandler { onTapped: root.run(tile.modelData) }
                    }
                }
            }

            // ── LIST ────────────────────────────────────────────────────────

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 7 * 60)
                visible: !root.idle && root.entries.length > 0
                clip: true
                spacing: 2
                model: root.idle ? [] : root.entries
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selected

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool chosen: row.index === root.selected
                    readonly property bool isApp: row.modelData.kind === "app" || row.modelData.kind === "minimized"
                    readonly property string picture: row.isApp && row.modelData.icon
                        ? Quickshell.iconPath(row.modelData.icon, true) : ""

                    width: ListView.view.width
                    height: 58
                    radius: 16
                    color: row.chosen ? Theme.surfaceHoverIn(root)
                        : rowHover.hovered ? Theme.surfaceIn(root) : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14
                        spacing: 14

                        // An application's own icon; a glyph on a tinted tile
                        // for everything else.
                        Item {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38

                            Image {
                                anchors.fill: parent
                                visible: row.picture !== ""
                                sourceSize.width: 76
                                sourceSize.height: 76
                                source: row.picture
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: row.picture === ""
                                radius: 11
                                color: Qt.rgba(root.tint(row.modelData.kind).r,
                                    root.tint(row.modelData.kind).g,
                                    root.tint(row.modelData.kind).b, 0.22)

                                Text {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: row.modelData.glyph || (row.isApp ? "󰀻" : (row.modelData.icon ?? ""))
                                    font.family: row.modelData.glyph ? Theme.fontFamily : Theme.fontMono
                                    font.pixelSize: row.modelData.glyph ? 22 : 17
                                    color: Theme.text
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.name ?? ""
                                elide: Text.ElideRight
                                font.family: row.modelData.kind === "calculation" ? Theme.fontMono : Theme.fontFamily
                                font.pixelSize: row.modelData.kind === "calculation" ? 18 : Theme.fontSizeRegular + 1
                                font.weight: Font.DemiBold
                                color: Theme.text
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: (row.modelData.subtitle ?? "") !== ""
                                text: row.modelData.subtitle ?? ""
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textMuted
                            }
                        }

                        // Enter's mark on the chosen row.
                        Rectangle {
                            visible: row.chosen
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 22
                            radius: 6
                            color: Theme.surfaceHoverIn(root)
                            border.color: Theme.borderIn(root)

                            Text {
                                anchors.centerIn: parent
                                text: "↵"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall + 1
                                color: Theme.text
                            }
                        }
                    }

                    HoverHandler {
                        id: rowHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) root.selected = row.index
                    }
                    TapHandler { onTapped: root.run(row.modelData) }
                }
            }

            // Nothing matched: the mode says what it wanted.
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 18
                Layout.bottomMargin: 18
                visible: !root.idle && root.entries.length === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.t(root.mode.empty)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                color: Theme.textMuted
            }

            // ── MODES ───────────────────────────────────────────────────────

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.borderIn(root)
            }

            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.bottomMargin: 2
                spacing: 6

                Repeater {
                    model: LauncherService.modes.filter(entry => entry.prefix !== "")

                    Rectangle {
                        id: chip

                        required property var modelData

                        readonly property bool on: chip.modelData.id === root.mode.id

                        width: chipRow.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: chip.on || chipHover.hovered ? Theme.surfaceHoverIn(root) : Theme.surfaceIn(root)
                        border.color: chip.on ? Theme.text : Theme.borderIn(root)
                        border.width: 1

                        Row {
                            id: chipRow

                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: chip.modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: chip.on ? Theme.text : Theme.textMuted
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Tr.t(chip.modelData.label)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: chip.on ? Theme.text : Theme.textMuted
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: chip.modelData.prefix
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textMuted
                                opacity: 0.7
                            }
                        }

                        HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                LauncherService.query = chip.on ? "" : chip.modelData.prefix
                                field.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }
    }
}

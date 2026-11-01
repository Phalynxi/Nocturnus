// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G S   P A N E L                                            │
// │   sections on the left, one page at a time on the right                  │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../theme"
import "../services"
import "../components"

// The sections across the top and one page under them. `SettingsWindow`
// owns the window; this owns the sections.
//
// Settings are filed by what they change, not by how they are applied, so the
// window rounding is under Appearance rather than on a compositor page. A
// section is one scrolling page: its parts follow one another, each under its
// own heading, rather than hiding behind tabs. Search lists the pages and the
// part that matched, and opening one scrolls straight to it.
//
// Where an option is a shape, the control is a live miniature built from the
// real components (`PreviewTile`), so it follows the palette and cannot go
// stale the way a screenshot would.
Item {
    id: root

    signal closed()
    signal panelRequested(string panel)

    readonly property int gap: 12

    // ── THE GROUPS ──────────────────────────────────────────────────────────

    readonly property var categories: [
        { id: "shell",   label: Tr.t("THE SHELL") },
        { id: "desk",    label: Tr.t("THE DESK") },
        { id: "session", label: Tr.t("THE SESSION") }
    ]

    // ── THE SECTIONS ────────────────────────────────────────────────────────
    //
    // One row per page. `keywords` are extra search terms beyond the label.
    readonly property var sections: [
        { id: "bar", category: "shell", icon: "󰧨", label: Tr.t("Bar & Island"),
          blurb: Tr.t("The top bar, the island and notifications."),
          tabs: [{ id: "island", label: Tr.t("The island") },
                 { id: "modules", label: Tr.t("The bar") },
                 { id: "workspaces", label: Tr.t("Workspaces") },
                 { id: "notifications", label: Tr.t("Notifications") }],
          keywords: "bar island notch height margin width full span workspaces unified layout island bar band notification toast do not disturb silence timeout clock time date seconds format beside running modules layout left right split drag catalogue chip icon ring figure hover shape media claude battery timer volume brightness network wifi bluetooth weather stats cpu updates capture record screenshot buttons every screen monitors ground glass classic blur transparent translucent codex",
          page: barPage },

        { id: "widgets", category: "shell", icon: "󰕮", label: Tr.t("Desktop"),
          blurb: Tr.t("What sits on the wallpaper, under the windows."),
          tabs: [{ id: "modules", label: Tr.t("Module settings") },
                 { id: "widgets", label: Tr.t("The widgets") }],
          keywords: "widgets desktop wallpaper widget place drag size shape capsule ground glass classic blur palette ink tray edit arrange clock calendar notes note sticky theme analogue modern opacity weather location place city github contributions username handwriting edges deck spectrum cava visualiser visualizer bars audio music",
          page: widgetsPage },

        { id: "dock", category: "shell", icon: "󱂩", label: Tr.t("Dock"),
          blurb: Tr.t("The dock and the applications kept on it."),
          tabs: [],
          keywords: "dock apps applications launcher pinned kept favourite favorite running edge bottom left right align icon size autohide taskbar menu windows close every screen monitors",
          page: dockPage },

        { id: "launcher", category: "shell", icon: "󰍉", label: Tr.t("Launcher"),
          blurb: Tr.t("Search, sigils and the clipboard history."),
          tabs: [{ id: "results", label: Tr.t("Results") },
                 { id: "sigils", label: Tr.t("Sigils") },
                 { id: "clipboard", label: Tr.t("Clipboard") }],
          keywords: "launcher search apps results calculate run window timer note task board prefix sigil order recent frequency favourite favorite pinned kept clipboard history copy paste images wipe lock",
          page: launcherPage },

        { id: "appearance", category: "desk", icon: "󰏘", label: Tr.t("Appearance"),
          blurb: Tr.t("Palette, windows, fonts and animations."),
          tabs: [{ id: "theme", label: Tr.t("Theme") },
                 { id: "windows", label: Tr.t("Windows") },
                 { id: "depth", label: Tr.t("Depth") },
                 { id: "type", label: Tr.t("Type") },
                 { id: "motion", label: Tr.t("Motion") }],
          keywords: "appearance theme colour color wallpaper transition fade wipe wave circle random greeting fastfetch fa terminal scene lava lamp critters koi invaders shadow shadows depth ground glass classic rounding blur gaps border opacity glass rules font family sans mono nerd icons typeface animation speed curve easing preset motion",
          page: appearancePage },

        { id: "monitors", category: "desk", icon: "󰍹", label: Tr.t("Displays"),
          blurb: Tr.t("Screen layout, modes and the laptop lid."),
          tabs: [{ id: "arrangement", label: Tr.t("Arrangement") },
                 { id: "screen", label: Tr.t("The screen") },
                 // A desktop has no lid to close.
                 { id: "lid", label: Tr.t("The lid"), when: MonitorService.internalName !== "" }],
          keywords: "displays monitor screen resolution refresh scale rotate transform vrr mirror extend primary lid clamshell laptop close workspaces",
          page: monitorsPage },

        { id: "input", category: "desk", icon: "󰍽", label: Tr.t("Input"),
          blurb: Tr.t("The keyboard, the pointer and the cursor."),
          tabs: [{ id: "keyboard", label: Tr.t("Keyboard") },
                 { id: "pointer", label: Tr.t("Pointer") }],
          keywords: "input keyboard layout repeat mouse sensitivity pointer cursor size theme shake find",
          page: inputPage },

        { id: "keys", category: "desk", icon: "󰌌", label: Tr.t("Keys"),
          blurb: Tr.t("Every keybinding, the shell's and Hyprland's."),
          tabs: [{ id: "shell", label: Tr.t("The shell's own") },
                 { id: "compositor", label: Tr.t("The compositor's") }],
          keywords: "keys shortcut binding hotkey super rebind",
          page: keysPage },

        { id: "session", category: "session", icon: "󰌾", label: Tr.t("Session"),
          blurb: Tr.t("Your account, the lock screen and idle behaviour."),
          tabs: [{ id: "lock", label: Tr.t("Lock screen") },
                 { id: "idle", label: Tr.t("When you leave") }],
          keywords: "session lock blur password suspend security idle timeout sleep screen off dpms away never lock after avatar picture name account clock stacked inline face unlock howdy camera infrared enrol enroll scan faces recognise",
          page: sessionPage },

        { id: "system", category: "session", icon: "󰍛", label: Tr.t("System"),
          blurb: Tr.t("Profiles, language, this machine and reset."),
          tabs: [{ id: "profiles", label: Tr.t("Profiles") },
                 { id: "machine", label: Tr.t("This machine") }],
          keywords: "system about version update updates upgrade changelog commits cpu memory uptime reset defaults language spanish english profile profiles switch rename duplicate delete import export backup file json changed files edited deleted restore wallpapers .new config dotfiles keep mine",
          page: systemPage }
    ]

    // ── NAVIGATION ──────────────────────────────────────────────────────────
    //
    // A history rather than a single id, so a page that links to another can
    // be left with Back. `tab` is now the part to scroll to, since a section
    // shows all its parts on one page.
    property var trail: [{ section: "bar", tab: "" }]
    property int cursor: 0

    readonly property string section: root.trail[root.cursor].section
    readonly property string tab: root.trail[root.cursor].tab

    readonly property var current:
        root.sections.find(entry => entry.id === root.section) ?? root.sections[0]

    // The parts a section shows, each under its own heading; a section
    // without parts is one. A part may only apply to some machines (`when`).
    function partsOf(entry: var): var {
        const parts = entry.tabs.filter(part => part.when === undefined || part.when)
        return parts.length > 0 ? parts : [{ id: "", label: "" }]
    }

    readonly property var parts: root.partsOf(root.current)

    function go(id: string, part: string): void {
        const wanted = part ?? ""
        if (id !== root.section || wanted !== root.tab) {
            const path = root.trail.slice(0, root.cursor + 1)
            path.push({ section: id, tab: wanted })
            root.trail = path
            root.cursor = path.length - 1
        }
        Qt.callLater(root.reveal)
    }

    // Scrolls to the part asked for, or to the top.
    function reveal(): void {
        const index = root.parts.findIndex(part => part.id === root.tab)
        const item = index > 0 ? partList.itemAt(index) : null
        page.contentY = item ? Math.min(item.y, Math.max(0, page.contentHeight - page.height)) : 0
    }

    function back(): void {
        if (root.cursor > 0) {
            root.cursor--
            Qt.callLater(root.reveal)
        }
    }

    property string filter: ""

    function term(): string {
        return root.filter.trim().toLowerCase()
    }

    function matches(entry: var): bool {
        const term = root.term()
        if (term === "")
            return true
        // Labels are translated; keywords are English, so both languages match.
        const parts = entry.tabs.map(part => part.label).join(" ").toLowerCase()
        return entry.label.toLowerCase().includes(term)
            || entry.keywords.includes(term)
            || entry.blurb.toLowerCase().includes(term)
            || parts.includes(term)
    }

    // Search results: each matching section, and the part whose name
    // matches when one does, so Enter or a click lands on it.
    readonly property var results: {
        const term = root.term()
        if (term === "")
            return []
        return root.sections.filter(entry => root.matches(entry)).map(entry => {
            const part = entry.tabs.find(other => other.label.toLowerCase().includes(term))
            return { id: entry.id, icon: entry.icon, label: entry.label,
                     blurb: entry.blurb, part: part ? part.id : "",
                     partLabel: part ? part.label : "" }
        })
    }

    function open(result: var): void {
        search.text = ""
        root.filter = ""
        root.go(result.id, result.part)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 18

        // ── NAVIGATION ──────────────────────────────────────────────────────
        //
        // The sections in one capsule across the top, each with its name, the
        // search beside it. Too many for a narrow window, so the capsule
        // scrolls sideways rather than wrapping.
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: Theme.surfaceIn(QsWindow.window)
                border.color: Theme.borderIn(QsWindow.window)
                border.width: 1

                Flickable {
                    id: strip

                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    contentWidth: tabs.implicitWidth
                    contentHeight: height
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    // A wheel turns the strip sideways.
                    WheelHandler {
                        onWheel: event => strip.contentX = Math.max(0, Math.min(
                            strip.contentWidth - strip.width, strip.contentX - event.angleDelta.y))
                    }

                    Row {
                        id: tabs

                        height: parent.height
                        spacing: 2

                        Repeater {
                            model: root.sections

                            Rectangle {
                                id: tab

                                required property var modelData

                                readonly property bool active:
                                    tab.modelData.id === root.section && root.term() === ""

                                height: tabs.height
                                width: tabRow.implicitWidth + 28
                                radius: height / 2
                                color: tab.active ? Theme.surfaceHoverIn(QsWindow.window)
                                    : tabHover.hovered ? Theme.surfaceIn(QsWindow.window) : "transparent"
                                border.color: tab.active ? Theme.borderIn(QsWindow.window) : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                                Row {
                                    id: tabRow

                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: tab.modelData.icon
                                        font.family: Theme.fontMono
                                        font.pixelSize: 14
                                        color: tab.active ? Theme.text : Theme.textMuted
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: tab.modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeRegular
                                        font.weight: tab.active ? Font.DemiBold : Font.Normal
                                        color: tab.active || tabHover.hovered ? Theme.text : Theme.textMuted
                                    }
                                }

                                HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.go(tab.modelData.id, "") }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 230
                Layout.preferredHeight: 44
                radius: 22
                color: search.activeFocus ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
                border.color: search.activeFocus ? Theme.text : Theme.borderIn(QsWindow.window)
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 9

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: Theme.textMuted
                    }

                    TextInput {
                        id: search

                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeRegular
                        color: Theme.text
                        selectByMouse: true
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        clip: true
                        focus: true

                        onTextEdited: root.filter = text

                        // Escape clears the field first, and closes the
                        // window only once it is empty.
                        Keys.onEscapePressed: event => {
                            if (search.text === "") {
                                event.accepted = false
                                return
                            }
                            search.text = ""
                            root.filter = ""
                        }

                        // Enter opens the first match.
                        Keys.onReturnPressed: {
                            if (root.results.length > 0)
                                root.open(root.results[0])
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: Tr.t("Search")
                            font: search.font
                            color: Theme.textMuted
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 22
                color: closeHover.hovered ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
                border.color: Theme.borderIn(QsWindow.window)
                border.width: 1

                Text {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "󰅖"
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: Theme.text
                }

                HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.closed() }
            }
        }

        // ── TITLE ───────────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            spacing: 12

            Rectangle {
                visible: root.cursor > 0 && root.term() === ""
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: backHover.hovered ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"

                Text {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "󰅁"
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: Theme.text
                }

                HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.back() }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.term() !== "" ? Tr.t("Search") : root.current.label
                    font.family: Theme.fontDisplay
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: Theme.text
                }

                Text {
                    Layout.fillWidth: true
                    text: root.term() !== ""
                        ? (root.results.length === 1 ? Tr.t("1 page") : `${root.results.length} ${Tr.t("pages")}`)
                        : root.current.blurb
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall + 1
                    color: Theme.textMuted
                }
            }
        }

        // ── RESULTS ─────────────────────────────────────────────────────────

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.term() !== ""
            clip: true
            spacing: 8
            model: root.results
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: result

                required property var modelData

                width: ListView.view.width
                height: 64
                radius: Theme.radiusLarge
                color: resultHover.hovered ? Theme.surfaceHoverIn(QsWindow.window) : Theme.surfaceIn(QsWindow.window)
                border.color: Theme.borderIn(QsWindow.window)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Text {
                        text: result.modelData.icon
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                        color: Theme.text
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: result.modelData.partLabel !== ""
                                ? `${result.modelData.label}  ›  ${result.modelData.partLabel}`
                                : result.modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeRegular
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        Text {
                            Layout.fillWidth: true
                            text: result.modelData.blurb
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textMuted
                        }
                    }

                    Text {
                        text: "󰅂"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: Theme.textMuted
                    }
                }

                HoverHandler { id: resultHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.open(result.modelData) }
            }

            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: Tr.t("Nothing matches")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                color: Theme.textMuted
            }
        }

        // ── SECTION ─────────────────────────────────────────────────────────
        //
        // Every part of the section on one scroll, each under its name.
        Flickable {
            id: page

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.term() === ""
            clip: true
            contentWidth: width
            contentHeight: body.implicitHeight + 24
            boundsBehavior: Flickable.StopAtBounds

            Behavior on contentY {
                enabled: !page.moving
                NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
            }

            ColumnLayout {
                id: body

                x: 8
                width: page.width - 16
                spacing: 30

                Repeater {
                    id: partList

                    model: root.parts

                    ColumnLayout {
                        id: part

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 14

                        Text {
                            visible: part.modelData.label !== ""
                            text: part.modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLarge + 2
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: root.current.page
                            onLoaded: item.tab = part.modelData.id
                        }
                    }
                }
            }
        }
    }

    Component { id: barPage;        BarSection {} }
    // Widgets are arranged on the desktop itself, behind this window.
    Component { id: widgetsPage;    WidgetsSection {
        onArranging: root.closed() } }
    Component { id: dockPage;       DockSection {} }
    Component { id: launcherPage;   LauncherSection {} }
    Component { id: appearancePage; AppearanceSection {
        onPanelRequested: name => root.panelRequested(name) } }
    Component { id: inputPage;      InputSection {} }
    Component { id: monitorsPage;   MonitorsSection {} }
    Component { id: keysPage;       KeysSection {} }
    Component { id: sessionPage;    SessionSection {} }
    Component { id: systemPage;     SystemSection {} }
}

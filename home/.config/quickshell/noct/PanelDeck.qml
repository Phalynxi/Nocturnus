// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P A N E L   D E C K                                                    │
// │   a card over a dimmed desk · every island panel, hosted here            │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar/island"
import "../bar/modules"
import "../components"
import "../services"
import "../theme"

PanelWindow {
    id: root

    signal settingsRequested()

    // ── OPEN PANEL ──────────────────────────────────────────────────────────
    //
    // One panel at a time, named as the island named them, so every panel's
    // own open/panel/back wiring keeps working unchanged.

    property string panel: ""
    readonly property bool shown: panel !== ""

    function toggle(name: string): void {
        panel === name ? close() : openPanel(name)
    }

    function openPanel(name: string): void {
        panel = name
    }

    function close(): void {
        panel = ""
    }

    // ── SIZES ───────────────────────────────────────────────────────────────
    //
    // The island's table, minus the pet (gone), the launcher (the shell has
    // one of its own), tray menus and module details (the ghost island owns
    // those). Games resize while a game plays.

    readonly property int overviewRows: Math.ceil(SettingsService.workspaceMax / 5)
    readonly property var appearanceSize: ({ width: 940, height: 200 })

    readonly property var sizes: ({
        controls:   { width: ControlsService.panelWidth, height: ControlsService.panelHeight },
        appearance: root.appearanceSize,
        palette:    root.appearanceSize,
        stats:      { width: 940, height: 614 },
        wifi:       { width: 420, height: 500 },
        sound:      { width: AudioService.panelWidth, height: AudioService.panelHeight },
        microphone: { width: AudioService.panelWidth, height: AudioService.microphoneHeight },
        nightlight: { width: SunsetService.panelWidth, height: SunsetService.panelHeight },
        brightness: { width: BrightnessService.panelWidth, height: BrightnessService.panelHeight },
        bluetooth:  { width: 420, height: 500 },
        session:    { width: 720, height: 180 },
        games:      GamesService.playing !== ""
            ? GamesService.panelSize(GamesService.playing)
            : { width: GamesService.shelfWidth, height: GamesService.shelfHeight },
        notes:      { width: NotesService.panelWidth, height: NotesService.panelHeight },
        board:      { width: TasksService.panelWidth, height: TasksService.panelHeight },
        keys:       { width: ShortcutService.sheetWidth, height: ShortcutService.sheetHeight },
        packages:   { width: PackagesService.panelWidth, height: PackagesService.panelHeight },
        overview:   { width: 1560, height: 72 + root.overviewRows * 190 }
    })

    readonly property var size: root.sizes[root.panel] ?? root.sizes.controls

    // One component per name; both palette names slide the same strips.
    readonly property var components: ({
        controls: controlsPanel,
        appearance: appearancePanel,
        palette: appearancePanel,
        wifi: networkDetail,
        sound: soundDetail,
        microphone: microphoneDetail,
        nightlight: nightLightDetail,
        brightness: brightnessDetail,
        bluetooth: bluetoothDetail,
        stats: statsPanel,
        overview: overviewPanel,
        session: sessionPanel,
        games: gamesPanel,
        notes: notesPanel,
        board: boardPanel,
        keys: keysPanel,
        packages: packagesPanel
    })

    // ── WINDOW ──────────────────────────────────────────────────────────────

    readonly property int pad: Theme.panelPadding

    WlrLayershell.namespace: "nocturnus-deck"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shown
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    visible: root.shown
    color: "transparent"

    // clicks reach the desk everywhere but the card
    mask: Region {
        item: card
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.shown && root.panel !== "" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    TapHandler {
        onTapped: root.close()
    }

    // The card: a FocusScope so one Escape covers every panel, delegating the
    // rest inward the way the island's own scope did.
    Rectangle {
        id: card

        anchors.centerIn: parent
        width: root.size.width + 2 * root.pad
        height: root.size.height + 2 * root.pad
        radius: 24
        color: Theme.islandSurface
        border.width: 1
        border.color: Theme.islandBorder

        FocusScope {
            anchors.fill: parent
            focus: root.shown
            Keys.onEscapePressed: root.close()

        // the panel, faded in like the island's
        Loader {
            id: content

            anchors.fill: parent
            anchors.margins: root.pad
            active: root.shown
            opacity: active ? 1 : 0
            sourceComponent: root.components[root.panel] ?? root.components.controls

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Item {
            id: panels
            anchors.fill: parent
            visible: false

            Component {
                id: controlsPanel
                ControlsPanel {
                    onClosed: root.close()
                    onPanelRequested: panel => root.openPanel(panel)
                    onSettingsRequested: {
                        root.close()
                        root.settingsRequested()
                    }
                }
            }

            Component {
                id: appearancePanel
                AppearancePanel {
                    page: root.panel === "palette" ? "palette" : "wallpaper"
                    onClosed: root.close()
                    onPanelRequested: panel => root.openPanel(panel)
                }
            }

            Component {
                id: networkDetail
                NetworkDetail { onBack: root.openPanel("controls") }
            }

            Component {
                id: soundDetail
                SoundDetail { onBack: root.openPanel("controls") }
            }

            Component {
                id: microphoneDetail
                MicrophoneDetail { onBack: root.openPanel("controls") }
            }

            Component {
                id: brightnessDetail
                BrightnessDetail { onBack: root.openPanel("controls") }
            }

            Component {
                id: nightLightDetail
                NightLightDetail { onBack: root.openPanel("controls") }
            }

            Component {
                id: bluetoothDetail
                BluetoothDetail { onBack: root.openPanel("controls") }
            }

            Component {
                id: statsPanel
                StatsPanel { onClosed: root.close() }
            }

            Component {
                id: overviewPanel
                OverviewPanel { onClosed: root.close() }
            }

            Component {
                id: sessionPanel
                SessionPanel { onClosed: root.close() }
            }

            Component {
                id: gamesPanel
                GamesPanel { onClosed: root.close() }
            }

            Component {
                id: notesPanel
                NotesPanel { onClosed: root.close() }
            }

            Component {
                id: boardPanel
                BoardPanel { onClosed: root.close() }
            }

            Component {
                id: keysPanel
                KeysPanel { onClosed: root.close() }
            }

            Component {
                id: packagesPanel
                PackagesPanel { onClosed: root.close() }
            }
        }
        }
    }
}

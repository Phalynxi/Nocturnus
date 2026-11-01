// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G S   W I N D O W                                          │
// │   settings window · a regular, movable window                            │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../theme"

// Settings is a window rather than an island panel, so the bar and island stay
// visible and react live while their own settings change.
//
// It is an xdg-shell toplevel, not a layer surface: Hyprland moves, resizes,
// focuses and closes it like any other window, and draws its rounding and
// shadow. `windowrules.lua` floats and sizes it, matched on the title.
FloatingWindow {
    id: root

    // Kept in sync with `visible` both ways, so closing the window from the
    // compositor resets it and it can be opened again.
    property bool shown: false

    function open(): void { root.shown = true }
    function close(): void { root.shown = false }
    function toggle(): void { root.shown = !root.shown }

    // Island panels are opened by the shell, not by this window.
    signal panelRequested(string panel)

    // Matched by the window rule in `windowrules.lua`.
    title: "Nocturnus Settings"

    // The bar's glass, made denser for a page of controls (`Theme.veilOf`'s
    // "pane"); solid when the bar is.
    readonly property bool glassy: true
    readonly property string groundStyle: Theme.glass ? "pane" : "classic"

    implicitWidth: 1100
    implicitHeight: 720

    // Over a frosted ground: the island's tint, mostly opaque on glass so the
    // cards read against it while the blur behind still shows at the edges.
    // A solid style keeps the island solid.
    color: Theme.glass
        ? Qt.rgba(Theme.islandGround.r, Theme.islandGround.g, Theme.islandGround.b, 0.88)
        : Theme.island
    visible: root.shown

    onVisibleChanged: {
        if (!root.visible && root.shown)
            root.shown = false
    }

    // Built on open and destroyed on close, so pages query state when created
    // and release their subscriptions when gone.
    Loader {
        anchors.fill: parent
        active: root.visible
        sourceComponent: panel
    }

    Component {
        id: panel

        SettingsPanel {
            onClosed: root.close()
            onPanelRequested: name => root.panelRequested(name)
        }
    }
}

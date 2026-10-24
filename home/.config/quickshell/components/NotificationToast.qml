// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N O T I F I C A T I O N   T O A S T                                   │
// │   floating notification · outside the bar                               │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../theme"
import "../services"
import "../bar/island"

// Floating toast that pops above the windows, anchored to the top‑right of
// the focused screen — the same chrome as the island's NotificationLayer,
// just freed from the bar's real estate.
PanelWindow {
    id: root

    // Follows the focused monitor; falls back to the primary screen.
    screen: HyprlandService.focusedMonitor
        ? (Quickshell.screens.find(s => s.name === HyprlandService.focusedMonitor)
           ?? Quickshell.primaryScreen)
        : Quickshell.primaryScreen

    // Top‑right, just under the bar's airspace.
    anchors.top: true
    anchors.right: true
    anchors.topMargin: SettingsService.barHeight + SettingsService.barMargin
    anchors.rightMargin: 16

    width: NotificationService.toastWidth
    height: NotificationService.toastHeight

    color: "transparent"

    WlrLayershell.namespace: "nocturnus-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: NotificationService.active && !SettingsService.doNotDisturb
        || NotificationService.critical

    // Reuse the island's chrome: picture, title, body, buttons.
    NotificationLayer {
        anchors.fill: parent
    }

    // Fade in / out with arrival and dismissal.
    opacity: root.visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
}

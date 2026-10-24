// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N O T I F I C A T I O N   T O A S T                                   │
// │   floating notification · outside the bar                               │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────┙

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

import "../theme"
import "../services"
import "../bar/island"

// Floating toast that pops above the windows, top‑right of the screen.
// Same chrome as the island's NotificationLayer, just freed from the bar.
PanelWindow {
    id: root

    // Full‑screen surface — content is positioned inside (like Dock, Hive).
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"
    WlrLayershell.namespace: "nocturnus-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    visible: ((NotificationService.active && !SettingsService.doNotDisturb)
        || NotificationService.critical)

    // ── THE TOAST ──────────────────────────────────────────────────────────
    NotificationLayer {
        id: toast

        width: NotificationService.toastWidth
        height: NotificationService.toastHeight

        // Top‑right, just under the bar's airspace.
        x: root.width - width - 16
        y: SettingsService.barHeight + SettingsService.barMargin

        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
    }
}

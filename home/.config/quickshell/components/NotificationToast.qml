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

    // A glass ground, like the bar's: nested `SurfaceIn` washes follow the
    // glass style, and the compositor's blur is asked for by the window's
    // namespace (`hyprglass.layer` on `nocturnus-toast`, in Hyprland's look).
    readonly property bool glassy: true
    // A fullscreen window anywhere: notifications duck under it, since the
    // toast's mapped window otherwise pulls focus mid-fight (Realm of games
    // included — a pilfered frame is a lost fight).
    readonly property bool fullscreen: HyprlandService.clients.some(
        client => (client.fullscreen ?? 0) >= 2)

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

    visible: true

    // ── THE TOAST ──────────────────────────────────────────────────────────
    // The island draws NotificationLayer inside its own chrome; the toast
    // stands alone, so it brings the pill surface here, with the same corner
    // rounding the island uses when it is not expanded. The ground is the
    // islands' (`Theme.islandGround`), which follows the palette and the
    // solid/glass style, sitting over the compositor's blur.
    Rectangle {
        id: toast

        width: NotificationService.toastWidth
        height: NotificationService.toastHeight
        radius: Math.min(height / 2, Theme.radiusLarge + 4)
        color: Theme.islandGround
        border.color: Theme.rimOf(Theme.styleIn(QsWindow.window))
        border.width: 1

        // Top‑right, just under the bar's airspace.
        x: root.width - width - 16
        y: SettingsService.barHeight + SettingsService.barMargin

        opacity: (NotificationService.active && !root.fullscreen) || NotificationService.critical ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

        // The island loads the layer inside its own padding, standing in for
        // the margins; the toast gives them here, so the row centres in the
        // pill as it does in the island.
        NotificationLayer {
            anchors.fill: parent
            anchors.topMargin: NotificationService.toastPadding
            anchors.bottomMargin: NotificationService.toastPadding
            anchors.leftMargin: NotificationService.toastPadding
            anchors.rightMargin: NotificationService.toastPadding
        }
    }
}

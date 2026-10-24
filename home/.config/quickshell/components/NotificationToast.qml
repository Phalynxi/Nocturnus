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
import Quickshell.Services.Notifications

import "../theme"
import "../services"
import "../bar/island"

// Floating toast that pops above the windows, anchored to the top‑right of
// the focused screen.  Reuses NotificationLayer's chrome (picture, title,
// body, buttons) so the look is identical to the island's old mode — just
// freed from the bar's real estate.
//
//   click          fire the default action (or dismiss)
//   right click    dismiss
PanelWindow {
    id: root

    // Follows the focused monitor; falls back to the primary screen.
    screen: HyprlandService.focusedMonitor
        ? (Quickshell.screens.find(s => s.name === HyprlandService.focusedMonitor)
           ?? Quickshell.primaryScreen)
        : Quickshell.primaryScreen

    anchors.top: true
    anchors.right: true
    anchors.topMargin: 48
    anchors.rightMargin: 16

    width: NotificationService.toastWidth
    height: NotificationService.toastHeight
    color: "transparent"

    WlrLayershell.namespace: "nocturnus-notif"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: NotificationService.active && !SettingsService.doNotDisturb
        || NotificationService.critical

    // The same chrome the island used to render, now floating.
    NotificationLayer {
        anchors.fill: parent
    }

    // Fade in / out with the arrival and dismissal.
    opacity: root.visible ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast }
    }

    // Click fires the default action; right click dismisses.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.LeftButton && NotificationService.defaultAction)
                NotificationService.invoke(NotificationService.defaultAction)
            else
                NotificationService.close()
        }
    }
}

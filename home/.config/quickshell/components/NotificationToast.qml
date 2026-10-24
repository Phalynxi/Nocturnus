// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N O T I F I C A T I O N   T O A S T                                   │
// │   floating notification · outside the bar                               │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╙

import QtQuick
import QtQuick.Window
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

    anchors.top: true
    anchors.right: true

    width: NotificationService.toastWidth
    height: NotificationService.toastHeight

    color: "transparent"
    WlrLayershell.namespace: "nocturnus-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    visible: ((NotificationService.active && !SettingsService.doNotDisturb)
        || NotificationService.critical)

    // Offset below the bar.
    x: Screen.width - width - 16
    y: SettingsService.barHeight + SettingsService.barMargin

    NotificationLayer {
        anchors.fill: parent

        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: event => {
                if (event.button === Qt.LeftButton
                    && NotificationService.defaultAction(root.notification))
                    NotificationService.invoke(
                        NotificationService.defaultAction(root.notification))
                else
                    NotificationService.close()
            }
        }
    }
}

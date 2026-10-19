// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   G H O S T   I S L A N D                                                │
// │   the old island's machine, running for notifications, the OSD and       │
// │   module details — silent at rest, so the bar owns the top edge          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar/widgets"
import "../services"
import "../theme"

PanelWindow {
    id: ghost

    WlrLayershell.namespace: "nocturnus-island"
    WlrLayershell.layer: WlrLayer.Top
    // A panel keyed a key or two needs the keyboard; notifications do not.
    WlrLayershell.keyboardFocus: painted && island.expanded
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 300
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Rest and summary belong to the bar capsule; panels opened by the
    // shortcuts belong to the deck. What remains here is what no other
    // window serves: notifications, the OSD and module details.
    readonly property bool painted: island.state.layer === "notification"
        || island.state.layer === "osd"
        || island.state.layer === "panel"

    // The island, centred where the old one sat, hanging under the bar. At
    // rest it paints nothing: the bar owns the quiet edge.
    DynamicIsland {
        id: island

        visible: ghost.painted
        x: (parent.width - width) / 2
        y: 64
    }

    // Clicks pass through everywhere but the island.
    mask: Region {
        item: island
    }
}

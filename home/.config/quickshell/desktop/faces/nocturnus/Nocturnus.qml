// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N   O   C   T   U   R   N   U   S                                      │
// │   the widget theme's registry · one row per module                       │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../../../services"
import "../analogue"

// The Nocturnus registry: one row per module. A single registry rather than
// one per family, because each face lays itself out at any family it backs.
// Faces read services and draw in `ink`; the widgets know nothing about the
// theme, whose ground is the capsule's glass. Modules not drawn yet hold the
// quiet lens until a face is written for them.
Item {
    id: root

    property string moduleId: ""
    property string family: "2x2"
    property var ink: DesktopService.inkFor(null)

    // The desktop row, for the one face that draws what the row names.
    property var row: null

    readonly property var components: ({
        clock: clockFace,
        media: mediaFace,
        stats: statsFace,
        photo: photoFace,
        timer: lens,
        battery: lens,
        volume: lens,
        brightness: lens,
        network: lens,
        bluetooth: lens,
        weather: lens,
        github: lens,
        updates: lens,
        pet: lens,
        games: lens,
        claude: lens,
        codex: lens,
        calendar: lens,
        tasks: lens,
        notes: lens,
        spectrum: lens
    })

    Loader {
        anchors.fill: parent
        sourceComponent: root.components[root.moduleId] ?? lens
    }

    Component { id: clockFace; NoctClock  { family: root.family; ink: root.ink } }
    Component { id: mediaFace; NoctMedia  { family: root.family; ink: root.ink } }
    Component { id: statsFace; NoctStats  { family: root.family; ink: root.ink } }
    Component { id: photoFace; PhotoFace  { family: root.family; ink: root.ink; row: root.row } }

    Component {
        id: lens

        NoctLens { moduleId: root.moduleId; family: root.family; ink: root.ink }
    }
}

// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P O S T E R                                                            │
// │   the poster registry · a headline clock and a forecast card             │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import "../../../services"
import "../nocturnus"

// The time set as a poster's headline straight on the wallpaper, and the
// weather as a full forecast card. Every other module wears its Nocturnus
// face, so a desk switched to Poster loses nothing.
Item {
    id: root

    property string moduleId: ""
    property string family: "4x2"
    property var ink: DesktopService.inkFor(null)
    property var row: null

    Loader {
        anchors.fill: parent
        sourceComponent: root.moduleId === "clock" ? clockFace
            : root.moduleId === "weather" ? weatherFace
            : nocturnus
    }

    Component { id: clockFace; PosterClock { family: root.family; ink: root.ink } }
    Component { id: weatherFace; PosterWeather { family: root.family; ink: root.ink } }

    Component {
        id: nocturnus

        Nocturnus { moduleId: root.moduleId; family: root.family; ink: root.ink; row: root.row }
    }
}

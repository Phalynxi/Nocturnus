// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   T R A Y   I C O N                                                      │
// │   a tray item's icon · in its own colours                                │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

// The item's own icon, in its own colours, as the reference bar wears them:
// `image://icon/<name>` resolves through the icon theme to the application's
// full-colour icon, and a picture the item sent is drawn as sent.
Item {
    id: root

    // `SystemTrayItem.icon`: `image://icon/<name>` or a picture the item sent.
    property string icon: ""

    Image {
        anchors.fill: parent
        sourceSize.width: root.width * 2
        sourceSize.height: root.height * 2
        source: root.icon
        smooth: true
    }
}

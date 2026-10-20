// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N   O   C   T   U   R   N   U   S   ·   M   E   D   I   A               │
// │   what is playing, as a bowled cover beside the words                    │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                          │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Widgets

import "../../../theme"
import "../../../services"
import "../../../components"
import "."

// The cover sits in its own bowl on the left — round, rimmed — and the words
// and a hairline of progress sit beside it. The transport is a quiet row of
// glyphs, no invitations. Without a player the face holds exactly what it
// is: one dimmed glyph, three words.
Item {
    id: root

    property string family: "4x2"
    property var ink: DesktopService.inkFor(null)

    readonly property bool hasCover: MediaService.artUrl !== ""
    readonly property string title: MediaService.title !== ""
        ? MediaService.title
        : (MediaService.available ? MediaService.identity : "Nothing playing")
    readonly property string subtitle: !MediaService.available
        ? "no player on the bus"
        : (MediaService.artist !== "" ? MediaService.artist + " · " : "")
            + (MediaService.playing ? "playing" : "paused")

    readonly property bool square: family === "2x2"

    // The cover in a bowl: round, one hairline of rim, a dimmed glyph when
    // there is nothing to show. The bowl's ground sits under the art for the
    // frames its decode takes.
    component Bowl: ClippingRectangle {
        id: bowl

        radius: width / 2
        color: root.ink.raised
        border.width: 1
        border.color: root.hasCover ? root.ink.border : Qt.rgba(
            root.ink.border.r, root.ink.border.g, root.ink.border.b, 0.4)

        Image {
            id: art

            anchors.fill: parent
            anchors.margins: 1
            visible: root.hasCover
            fillMode: Image.PreserveAspectCrop
            source: root.hasCover ? MediaService.artUrl : ""
            sourceSize.width: 480
            sourceSize.height: 480
            asynchronous: true
        }

        Text {
            anchors.centerIn: parent
            visible: !root.hasCover
            text: "󰝚"
            font.family: Theme.fontMono
            font.pixelSize: root.family === "2x2"
                ? Theme.fontSizeWidget * 0.95 : Theme.fontSizeWidget * 1.35
            color: root.ink.muted
        }
    }

    // Squares: the bowl and the track under it, no controls.
    Instrument {
        visible: root.square
        anchors.fill: parent
        family: root.family
        ink: root.ink
        line: root.title

        Bowl {
            width: parent.width
            height: parent.height
        }
    }

    // Wide and large: the Instrument layout — bowl beside the words — with
    // the hairline and transport as `extra`; on a 4×4 those drop into the
    // body under the bowl, breathing into the half below.
    Instrument {
        visible: !root.square
        anchors.fill: parent
        family: root.family
        ink: root.ink
        reading: root.title
        note: root.subtitle

        Bowl {
            width: parent.width
            height: parent.height
        }

        extra: [
            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 12

                UsageBar {
                    width: parent.width
                    height: 4
                    progress: MediaService.progress
                    fillColor: root.ink.accent
                    trackColor: root.ink.raised
                }

                Row {
                    spacing: 18

                    IconButton {
                        iconColor: root.ink.text
                        icon: "󰒮"
                        iconSize: 17
                        onClicked: MediaService.previous()
                    }

                    IconButton {
                        iconColor: root.ink.text
                        icon: MediaService.playing ? "󰏤" : "󰐊"
                        iconSize: 19
                        onClicked: MediaService.toggle()
                    }

                    IconButton {
                        iconColor: root.ink.text
                        icon: "󰒭"
                        iconSize: 17
                        onClicked: MediaService.next()
                    }
                }
            }
        ]

        body: [
            Column {
                anchors.fill: parent
                spacing: 18

                UsageBar {
                    width: parent.width
                    height: 4
                    progress: MediaService.progress
                    fillColor: root.ink.accent
                    trackColor: root.ink.raised
                }

                Row {
                    spacing: 26

                    IconButton {
                        iconColor: root.ink.text
                        icon: "󰒮"
                        iconSize: 22
                        onClicked: MediaService.previous()
                    }

                    IconButton {
                        iconColor: root.ink.text
                        icon: MediaService.playing ? "󰏤" : "󰐊"
                        iconSize: 25
                        onClicked: MediaService.toggle()
                    }

                    IconButton {
                        iconColor: root.ink.text
                        icon: "󰒭"
                        iconSize: 22
                        onClicked: MediaService.next()
                    }
                }
            }
        ]
    }
}

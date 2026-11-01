// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I N B O X   M O D U L E                                                │
// │   GitHub notifications · unread count, the newest and quick links        │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../theme"
import "../../services"
import "../../components"

// The unread count on the bar; the detail lists the newest four, each
// opening its page (and so marked read), with the inbox, your pull requests
// and a clear-all under them.
Item {
    id: root

    // How many rows the card shows (`ModuleService.openSize` agrees).
    readonly property int shown: 4

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Component.onCompleted: InboxService.subscribe()
    Component.onDestruction: InboxService.release()

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        ModuleCard {
            title: InboxService.count === 0 ? "Inbox zero"
                : InboxService.count === 1 ? "1 unread" : `${InboxService.count} unread`
            subtitle: "GitHub notifications"

            mark: Text {
                anchors.centerIn: parent
                text: ""
                font.family: Theme.fontMono
                font.pixelSize: 22
                color: InboxService.count > 0 ? Theme.indicator : Theme.textMuted
            }

            Repeater {
                model: InboxService.items.slice(0, root.shown)

                // One notification: what kind, its title, and the repository.
                Item {
                    id: note

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.cardRow

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: Theme.radiusSmall
                        color: hover.hovered ? Theme.surfaceHover : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 16
                            text: note.modelData.kind === "Pull request" ? ""
                                : note.modelData.kind === "Issue" ? ""
                                : note.modelData.kind === "Checks" ? ""
                                : note.modelData.kind === "Release" ? "" : ""
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: note.modelData.kind === "Checks" ? Theme.indicatorBad : Theme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: note.modelData.title
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall + 1
                            color: Theme.text
                        }

                        Text {
                            Layout.maximumWidth: 120
                            text: note.modelData.repo.split("/").pop()
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textMuted
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: InboxService.open(note.modelData)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.cardRow
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: InboxService.count > root.shown ? `and ${InboxService.count - root.shown} more` : ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textMuted
                }

                PillButton {
                    implicitHeight: Theme.cardRow
                    text: "Inbox"
                    onClicked: InboxService.openUrl("https://github.com/notifications")
                }

                PillButton {
                    implicitHeight: Theme.cardRow
                    text: "Pulls"
                    onClicked: InboxService.openUrl("https://github.com/pulls")
                }

                PillButton {
                    implicitHeight: Theme.cardRow
                    text: "Mark all read"
                    active: InboxService.count > 0
                    enabled: InboxService.count > 0
                    onClicked: InboxService.markAllRead()
                }
            }
        }
    }
}

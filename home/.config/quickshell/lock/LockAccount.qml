// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L O C K   A C C O U N T                                                │
// │   the account pill · picture and name, then the password field           │
// │                                                                          │
// │   github.com/Phalynxi/Nocturnus                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io

import "../theme"
import "../services"
import "../components"

// One black pill: the picture, the name and how to get in; from the first
// character, the same pill stretched into the field with the dots and a
// button to send them. The field holds the keyboard all along, invisible
// until there is something in it.
Item {
    id: root

    signal submitted(string password)

    function claim(): void {
        field.forceActiveFocus()
    }

    function clear(): void {
        field.clear()
    }

    readonly property bool typing: field.text !== ""
        || LockService.authenticating
        || LockService.failed

    readonly property int pillHeight: 60
    readonly property int face: 48
    readonly property int inset: 6
    readonly property int fieldWidth: 380

    implicitWidth: pill.width
    implicitHeight: root.pillHeight + 40

    // ── USER LIST ──────────────────────────────────────────────────────────

    // System users (UID >= 1000). Populated once on first wake.
    property var userList: []

    readonly property Process userLoader: Process {
        command: ["sh", "-c", "getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1 \"|\" $5 \"|\" $6}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "")
                    return
                const lines = text.trim().split("\n").filter(l => l !== "")
                const users = []
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split("|")
                    if (parts.length >= 3) {
                        users.push({ name: parts[0], fullName: parts[1] || parts[0], home: parts[2] })
                    }
                }
                const current = AccountService.user
                users.sort(function(a, b) {
                    if (a.name === current) return -1
                    if (b.name === current) return 1
                    return 0
                })
                root.userList = users
            }
        }
    }

    function loadUsers(): void {
        if (root.userList.length === 0 && !root.userLoader.running)
            root.userLoader.running = true
    }

    // ── PILL ────────────────────────────────────────────────────────────────

    Item {
        id: holder

        anchors.horizontalCenter: parent.horizontalCenter
        width: pill.width
        height: pill.height

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1
            shadowOpacity: 0.5
            shadowVerticalOffset: 4
            shadowColor: Theme.island
        }

        // Shakes on a wrong password; the shake is seen before the text below.
        SequentialAnimation {
            id: refusal

            loops: 2
            NumberAnimation { target: holder; property: "anchors.horizontalCenterOffset"
                to: -9; duration: 55; easing.type: Easing.OutCubic }
            NumberAnimation { target: holder; property: "anchors.horizontalCenterOffset"
                to: 9; duration: 55; easing.type: Easing.OutCubic }
            NumberAnimation { target: holder; property: "anchors.horizontalCenterOffset"
                to: 0; duration: 55; easing.type: Easing.OutCubic }
        }

        Connections {
            target: LockService
            function onFailedChanged(): void {
                if (LockService.failed)
                    refusal.restart()
            }
        }

        Rectangle {
            id: pill

            width: root.typing
                ? root.fieldWidth
                : root.inset + root.face + 14 + resting.implicitWidth + 26
            height: root.pillHeight
            radius: Theme.radiusPill
            // The island's ground: glass over the blurred desktop, or solid.
            color: Theme.islandGround
            border.width: 1
            border.color: {
                if (LockService.failed)
                    return Theme.indicatorBad
                return root.typing ? Theme.accent : Theme.veilLineOf(Theme.surfaceStyle)
            }

            Behavior on width {
                NumberAnimation { duration: Theme.durationMorph; easing.type: Theme.easing }
            }
            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

            // Anywhere on the pill wakes the screen and puts the keyboard back
            // in the field.
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: {
                    LockService.rouse()
                    field.forceActiveFocus()
                }
            }

            // ── AVATAR WITH USER DROPDOWN ──────────────────────────────────

            Item {
                id: avatarWrapper

                x: root.inset
                anchors.verticalCenter: parent.verticalCenter
                width: root.face
                height: root.face

                // Blue ring on hover (SDDM style)
                Rectangle {
                    id: hoverRing

                    anchors.fill: parent
                    radius: width / 2
                    border.width: 2
                    border.color: Theme.accent
                    opacity: avatarArea.containsMouse ? 1 : 0
                    visible: avatarArea.containsMouse

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durationFast }
                    }
                }

                Avatar {
                    id: picture

                    anchors.fill: parent
                    source: AccountService.avatar
                    initials: AccountService.initials
                }

                MouseArea {
                    id: avatarArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (mouse.button === Qt.LeftButton) {
                            loadUsers()
                            userDropdown.popup()
                        }
                    }
                }

                // User dropdown (dropup since we're near bottom)
                Menu {
                    id: userDropdown

                    transformOrigin: Item.BottomLeft
                    x: avatarWrapper.x
                    y: avatarWrapper.y

                    // Build items from userList when opening
                    onAboutToShow: {
                        userDropdown.clear()
                        for (let i = 0; i < root.userList.length; i++) {
                            const u = root.userList[i]
                            const item = userDropdown.addItem(u.fullName)
                            item.userName = u.name
                            if (u.name === AccountService.user) {
                                item.font.bold = true
                            }
                            item.triggered.connect(function() {
                                if (item.userName !== AccountService.user) {
                                    SessionService.run("switchUser")
                                }
                            })
                        }
                    }
                }
            }

            // ── AT REST ─────────────────────────────────────────────────────

            Column {
                id: resting

                anchors.left: avatarWrapper.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                opacity: root.typing ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }

                Text {
                    text: AccountService.name
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Theme.text
                }

                Text {
                    text: LockService.faceReady ? "Face unlock or password"
                                                : "Enter your password"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    color: Theme.textMuted
                }
            }

            // ── TYPING ──────────────────────────────────────────────────────

            TextInput {
                id: field

                anchors.left: avatarWrapper.right
                anchors.leftMargin: 18
                anchors.right: send.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.typing ? 1 : 0

                echoMode: TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                enabled: !LockService.authenticating && !LockService.leaving
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.letterSpacing: 3
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                clip: true

                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }

                Connections {
                    target: LockService
                    function onTypedChanged(): void {
                        if (field.text !== LockService.typed)
                            field.text = LockService.typed
                    }
                }

                onAccepted: {
                    root.submitted(field.text)
                    field.clear()
                }

                // Typing clears the error, and reaches every screen.
                onTextChanged: {
                    if (field.text !== LockService.typed)
                        LockService.typed = field.text
                    if (LockService.failed && field.text !== "")
                        LockService.failed = false
                }

                // Escape takes the password off the screen and the screen back
                // to its clock.
                Keys.onEscapePressed: {
                    field.clear()
                    LockService.rest()
                }

                // Any other key is somebody there and wakes the screen, bar
                // Shift and Caps Lock on their own. The key that wakes it only
                // opens it and types nothing; once awake, keys reach the field.
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Shift || event.key === Qt.Key_CapsLock
                            || event.key === Qt.Key_Escape)
                        return
                    event.accepted = !LockService.awake
                    LockService.rouse()
                }
            }

            // Sends what is typed; a spinner while PAM checks it.
            Rectangle {
                id: send

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: width / 2
                color: LockService.authenticating ? "transparent"
                    : (press.containsMouse ? Theme.textMuted : Theme.text)
                opacity: root.typing ? 1 : 0
                scale: root.typing ? 1 : 0.6
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easing }
                }
                Behavior on scale {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.OutBack }
                }
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    anchors.centerIn: parent
                    visible: !LockService.authenticating
                    text: "󰁔"
                    font.family: Theme.fontMono
                    font.pixelSize: 20
                    color: Theme.island
                }

                RingIndicator {
                    id: spinner

                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    visible: LockService.authenticating
                    thickness: 2
                    progress: 0.28
                    trackColor: "transparent"
                    fillColor: Theme.text

                    RotationAnimator {
                        target: spinner
                        running: LockService.authenticating
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: press

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !LockService.authenticating
                    onClicked: {
                        root.submitted(field.text)
                        field.clear()
                    }
                }
            }
        }
    }

    // ── MESSAGE ─────────────────────────────────────────────────────────────

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: holder.bottom
        anchors.topMargin: 14
        text: LockService.message
        visible: text !== ""
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.indicatorBad

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.8
            shadowOpacity: 0.7
            shadowColor: Theme.island
        }
    }
}
// Glass lock screen. Lock via `qs ipc call lockscreen lock` (Super+L).
// Unlock with your login password. Emergency exit: TTY + `pkill -x quickshell`.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io

Scope {
  ShellFont { id: shellFont }
  id: root

  IpcHandler {
    target: "lockscreen"
    function lock(): void { sessionLock.locked = true; }
    function unlock(): void { sessionLock.unlock(); }
  }

  WlSessionLock {
    id: sessionLock
    locked: false

    WlSessionLockSurface {
      color: "transparent"

      // PAM lives inside the surface: one session per screen, same scope as the field.
      PamContext {
        id: pam
        config: "hyprlock"
        user: Quickshell.env("USER")
        Component.onCompleted: pam.start()
        onCompleted: result => {
          if (result === PamResult.Success) {
            sessionLock.unlock();
          } else {
            statusRect.statusMsg = "Wrong password, try again";
            passInput.text = "";
            passInput.forceActiveFocus();
          }
        }
        // fail open on auth errors so a broken PAM setup can't lock you out
        onError: e => sessionLock.unlock()
      }

      Rectangle {
        id: statusRect
        property string statusMsg: ""
        anchors.fill: parent
        color: "#b3000000"
      }

      Column {
        anchors.centerIn: parent
        spacing: 18

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          SystemClock { id: lockClock; precision: SystemClock.Minutes }
          text: Qt.formatDateTime(lockClock.date, "HH:mm")
          color: "#ffffff"
          font.family: shellFont.family; font.pixelSize: 84; font.bold: true
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(lockClock.date, "dddd, MMM d")
          color: Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 16
        }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 300; height: 48
          radius: 16
          color: Theme.ground(0x33/255)
          Row {
            anchors.fill: parent
            anchors.leftMargin: 16; anchors.rightMargin: 16
            spacing: 10
            Lucide { anchors.verticalCenter: parent.verticalCenter; name: "lock"; px: 18 }
            TextInput {
              id: passInput
              width: parent.width - 28
              anchors.verticalCenter: parent.verticalCenter
              color: "#ffffff"
              font.family: shellFont.family; font.pixelSize: 15
              echoMode: TextInput.Password
              passwordCharacter: "•"
              focus: true
              onAccepted: {
                if (text !== "") pam.respond(text);
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: statusRect.statusMsg !== "" ? statusRect.statusMsg : "Enter password to unlock"
          color: statusRect.statusMsg !== "" ? Theme.red : Theme.textMuted
          font.family: shellFont.family; font.pixelSize: 12
        }
      }
    }
  }
}

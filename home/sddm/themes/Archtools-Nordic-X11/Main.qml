import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12
import Sddm 1.3

Rectangle {
  id: root
  width: 1920; height: 1080
  // Paleta Nordic darker (X11)
  readonly property color nord0: "#2E3440" // base
  readonly property color nord1: "#3B4252" // panel
  readonly property color nord2: "#434C5E" // borde
  readonly property color nord3: "#4C566A" // selección
  readonly property color nord4: "#D8DEE9" // texto claro
  readonly property color nord5: "#E5E9F0"
  readonly property color nord6: "#ECEFF4"
  readonly property color nord7: "#8FBCBB" // acentos
  readonly property color nord8: "#88C0D0"
  readonly property color nord9: "#81A1C1"
  readonly property color nord10: "#5E81AC"
  color: nord0

  property string defaultSession: "bspwm"

  // Background: try PNG, fallback to JPG
  Image {
    id: bgpng
    anchors.fill: parent
    source: "assets/bg.png"
    fillMode: Image.PreserveAspectCrop
  }
  Image {
    id: bgjpg
    anchors.fill: parent
    source: "assets/bg.jpg"
    fillMode: Image.PreserveAspectCrop
    visible: bgpng.status !== Image.Ready
  }

    Rectangle {
    id: panel
    width: 420; height: 250
    radius: 12
    color: nord1
    opacity: 0.94
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    border.color: nord2; border.width: 1

    Column {
      anchors.fill: parent
      anchors.margins: 24
      spacing: 12

      TextField {
        id: userField
        placeholderText: "Username"
        font.pixelSize: 16
        color: nord6
        selectionColor: nord3
        background: Rectangle { color: nord0; radius: 6; border.color: nord2 }
        text: sddm.lastUser || ""
      }

      TextField {
        id: passField
        placeholderText: "Password"
        echoMode: TextInput.Password
        font.pixelSize: 16
        color: nord6
        selectionColor: nord3
        background: Rectangle { color: nord0; radius: 6; border.color: nord2 }
      }

      Row {
        spacing: 12
        Button {
          id: loginBtn
          text: "Login"
          contentItem: Label { text: loginBtn.text; color: nord0; font.bold: true }
          background: Rectangle { radius: 6; color: nord8; border.color: nord10 }
          onClicked: {
            var sessionName = defaultSession
            sddm.login(userField.text, passField.text, sessionName)
          }
        }
      }

      // No extra controls: minimal UI
    }
  }

  // Minimal: no clock, no hostname, no power actions
}
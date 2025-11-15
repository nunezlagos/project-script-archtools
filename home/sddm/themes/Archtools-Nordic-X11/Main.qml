import QtQuick 2.0
import QtQuick.Controls 2.0
import Qt.labs.folderlistmodel 2.1

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
  readonly property color accentRed: "#BF616A" // red accent
  color: nord0

  property string defaultSession: "bspwm"
  property string selectedSession: defaultSession

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
  // Dark overlay to improve contrast
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0,0,0,0.35)
  }
  Rectangle {
    // Explicit fallback if both images fail to load
    anchors.fill: parent
    color: nord0
    visible: bgpng.status !== Image.Ready && bgjpg.status !== Image.Ready
  }

    // Soft shadow behind panel (simple rectangle, no GraphicalEffects)
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: 540; height: 340
      radius: 18
      color: "#000000"
      opacity: 0.25
    }

    Rectangle {
    id: panel
    width: 520; height: 320
    radius: 16
    color: nord1
    opacity: 0.94
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    border.color: nord2; border.width: 1

    Column {
      anchors.fill: parent
      anchors.margins: 28
      spacing: 16

      Label { text: "Username"; color: nord4 }
      TextField {
        id: userField
        placeholderText: "Username"
        font.pixelSize: 16
        color: nord6
        selectionColor: nord3
        background: Rectangle { color: nord0; radius: 6; border.color: nord2 }
        text: sddm.lastUser || ""
        Keys.onReturnPressed: passField.focus = true
      }

      Label { text: "Password"; color: nord4 }
      TextField {
        id: passField
        placeholderText: "Password"
        echoMode: TextInput.Password
        font.pixelSize: 16
        color: nord6
        selectionColor: nord3
        background: Rectangle { color: nord0; radius: 6; border.color: nord2 }
        Keys.onReturnPressed: loginBtn.clicked()
      }

      Row {
        spacing: 12
        // Session selector (bspwm/i3/etc.) from /usr/share/xsessions
        Column {
          spacing: 6
          Label { text: "Session"; color: nord4 }
          ComboBox {
            id: sessionCombo
            model: xsessions
            textRole: "fileName"
            width: 220
            onActivated: {
              var fname = xsessions.get(index).fileName
              selectedSession = fname.replace(".desktop", "")
            }
          }
        }
        Button {
          id: loginBtn
          text: "Login"
          contentItem: Label { text: loginBtn.text; color: nord6; font.bold: true }
          background: Rectangle { radius: 6; color: accentRed; border.color: nord9 }
          onClicked: {
            sddm.login(userField.text, passField.text, selectedSession)
          }
        }
      }

      // No extra controls: minimal UI
    }
  }

  // List available X sessions from desktop files
  FolderListModel {
    id: xsessions
    folder: "/usr/share/xsessions"
    nameFilters: ["*.desktop"]
    showDirs: false
    onCountChanged: {
      // Preselect default session if present
      for (var i = 0; i < count; i++) {
        var fn = xsessions.get(i).fileName
        if (fn === defaultSession + ".desktop") {
          sessionCombo.currentIndex = i
          selectedSession = defaultSession
          break
        }
      }
    }
  }

  // Minimal: no clock, no hostname, no power actions
}
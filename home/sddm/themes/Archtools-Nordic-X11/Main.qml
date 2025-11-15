import QtQuick 2.0
import QtQuick.Controls 2.0
import Qt.labs.folderlistmodel 2.1

Rectangle {
  id: root
  width: 1920; height: 1080
  // Paleta monocromática (grises/negros/blancos)
  readonly property color bgDark: "#0E0F12"
  readonly property color panelDark: "#1A1C1F"
  readonly property color borderLight: Qt.rgba(1,1,1,0.22) // blanco sutil
  readonly property color textLight: "#FFFFFF"            // blanco para texto
  readonly property color textMuted: Qt.rgba(1,1,1,0.70)  // blanco atenuado
  color: bgDark

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
  // Overlay para mejorar el contraste
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0,0,0,0.30)
  }
  Rectangle {
    // Explicit fallback if both images fail to load
    anchors.fill: parent
    color: nord0
    visible: bgpng.status !== Image.Ready && bgjpg.status !== Image.Ready
  }

    // Sombra suave detrás del panel (sin GraphicalEffects)
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: 540; height: 340
      radius: 5
      color: "#000000"
      opacity: 0.25
    }

    Rectangle {
    id: panel
    width: 520; height: 320
    radius: 5
    color: panelDark
    opacity: 0.94
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    border.color: borderLight; border.width: 1

    Column {
      anchors.fill: parent
      anchors.margins: 28
      spacing: 16

      Label { text: "Username"; color: textMuted }
      TextField {
        id: userField
        placeholderText: "Username"
        font.pixelSize: 16
        color: textLight
        selectionColor: Qt.rgba(1,1,1,0.25)
        background: Rectangle { color: panelDark; radius: 5; border.color: borderLight }
        text: sddm.lastUser || ""
        Keys.onReturnPressed: passField.focus = true
      }

      Label { text: "Password"; color: textMuted }
      TextField {
        id: passField
        placeholderText: "Password"
        echoMode: TextInput.Password
        font.pixelSize: 16
        color: textLight
        selectionColor: Qt.rgba(1,1,1,0.25)
        background: Rectangle { color: panelDark; radius: 5; border.color: borderLight }
        Keys.onReturnPressed: loginBtn.clicked()
      }

      Row {
        spacing: 12
        // Session selector (bspwm/i3/etc.) from /usr/share/xsessions
        Column {
          spacing: 6
          Label { text: "Session"; color: textMuted }
          ComboBox {
            id: sessionCombo
            model: xsessions
            textRole: "fileName"
            width: 220
            background: Rectangle { color: Qt.rgba(1,1,1,0.08); radius: 5; border.color: borderLight }
            onActivated: {
              var fname = xsessions.get(index).fileName
              selectedSession = fname.replace(".desktop", "")
            }
          }
        }
        Button {
          id: loginBtn
          text: "Login"
          contentItem: Label { text: loginBtn.text; color: textLight; font.bold: true }
          background: Rectangle {
            radius: 5
            color: Qt.rgba(1,1,1,0.12)
            border.color: borderLight
          }
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
import QtQuick 2.0
import QtQuick.Controls 2.0
import Qt.labs.folderlistmodel 2.1
import QtQml 2.0

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
    color: Qt.rgba(0,0,0,0.90)
  }
  Rectangle {
    // Explicit fallback if both images fail to load
    anchors.fill: parent
    color: bgDark
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
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        selectionColor: Qt.rgba(1,1,1,0.25)
        background: Rectangle { color: panelDark; radius: 5; border.color: parent.activeFocus ? Qt.rgba(1,1,1,0.45) : borderLight }
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
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        selectionColor: Qt.rgba(1,1,1,0.25)
        background: Rectangle { color: panelDark; radius: 5; border.color: parent.activeFocus ? Qt.rgba(1,1,1,0.45) : borderLight }
        Keys.onReturnPressed: loginBtn.clicked()
      }

      Item {
        width: parent.width
        height: 48
        Button {
          id: loginBtn
          anchors.horizontalCenter: parent.horizontalCenter
          width: panel.width * 0.5
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

  // Footer: hora/fecha y selector de sesión (icono engranaje)
  Row {
    id: footer
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 24
    spacing: 12
    Text {
      id: clockText
      color: textLight
      font.pixelSize: 16
      text: Qt.formatDateTime(new Date(), "HH:mm - dddd dd MMM")
    }
    Button {
      id: sessionBtn
      text: "⚙"
      contentItem: Label { text: sessionBtn.text; color: textLight; font.bold: true }
      background: Rectangle {
        radius: 5
        color: Qt.rgba(1,1,1,0.12)
        border.color: borderLight
      }
      onClicked: sessionMenu.open()
    }
  }

  Menu {
    id: sessionMenu
    Instantiator {
      model: xsessions
      delegate: MenuItem {
        text: model.fileName.replace(".desktop","")
        onTriggered: selectedSession = text
      }
      onObjectAdded: sessionMenu.insertItem(index, object)
      onObjectRemoved: sessionMenu.removeItem(object)
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm - dddd dd MMM")
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
          selectedSession = defaultSession
          break
        }
      }
    }
  }

  // Minimal: no clock, no hostname, no power actions
}
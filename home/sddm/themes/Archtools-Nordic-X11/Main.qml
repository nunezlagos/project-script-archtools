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
  property string selectedSession: defaultSession   // display name (e.g., bspwm)

  // Background: prefer login.png, fallback to login.jpg
  Image {
    id: bglgn
    anchors.fill: parent
    source: Qt.resolvedUrl("assets/login.png")
    fillMode: Image.PreserveAspectCrop
  }
  // Overlay para mejorar el contraste
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0,0,0,0.50)
  }

    // Sombra exterior eliminada

    Rectangle {
    id: panel
    width: 400; height: 200
    radius: 5
    color: panelDark
    opacity: 0.80
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    border.width: 0
    gradient: Gradient {
      GradientStop { position: 0.0; color: panelDark }
      GradientStop { position: 1.0; color: "#141619" }
    }

    Column {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 12
      // Padding superior general
      Item { height: 30 }

  
      TextField {
        id: userField
        placeholderText: "Username"
        font.pixelSize: 16
        color: textLight
        width: 360; height: 32
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        selectionColor: Qt.rgba(1,1,1,0.25)
        background: Rectangle { color: panelDark; radius: 5; border.color: parent.activeFocus ? Qt.rgba(1,1,1,0.45) : borderLight }
        text: sddm.lastUser || ""
        Keys.onReturnPressed: passField.focus = true
      }

      Item { height: 30 }
 
      TextField {
        id: passField
        placeholderText: "Password"
        echoMode: TextInput.Password
        font.pixelSize: 16
        color: textLight
        width: 360; height: 32
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        selectionColor: Qt.rgba(1,1,1,0.25)
        background: Rectangle { color: panelDark; radius: 5; border.color: parent.activeFocus ? Qt.rgba(1,1,1,0.45) : borderLight }
        Keys.onReturnPressed: sddm.login(userField.text, passField.text, selectedSession)
      }

      // Padding superior antes del botón
      Item { height: 30 }
      Button {
        id: loginBtn
        width: 200; height: 32
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Login"
        hoverEnabled: true
        contentItem: Label {
          anchors.fill: parent
          text: loginBtn.text
          color: textLight
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
          radius: 5
          color: loginBtn.pressed ? Qt.rgba(1,1,1,0.22)
                : loginBtn.hovered ? Qt.rgba(1,1,1,0.18)
                : Qt.rgba(1,1,1,0.12)
          border.color: borderLight
        }
        onClicked: {
          sddm.login(userField.text, passField.text, selectedSession)
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
      onClicked: sessionPopup.open()
    }
  }

  Popup {
    id: sessionPopup
    x: footer.x + footer.width - width
    y: footer.y - height - 8
    width: 160
    padding: 8
    background: Rectangle {
      radius: 5
      color: panelDark
      border.color: borderLight
      border.width: 1
    }
    contentItem: ListView {
      clip: true
      model: xsessions
      delegate: ItemDelegate {
        width: sessionPopup.width - 16
        text: model.fileName.replace(".desktop", "")
        onClicked: { selectedSession = text; sessionPopup.close(); }
      }
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
    folder: "file:///usr/share/xsessions"
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
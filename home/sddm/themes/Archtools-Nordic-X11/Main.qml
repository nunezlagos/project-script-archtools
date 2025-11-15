import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12
import Sddm 1.3

Rectangle {
  id: root
  width: 1920; height: 1080
  color: "#101418"

  property string defaultSession: "bspwm"

  Image {
    id: bg
    anchors.fill: parent
    source: "assets/bg.jpg"
    fillMode: Image.PreserveAspectCrop
    visible: true
  }

  Rectangle {
    id: panel
    width: 480; height: 360
    radius: 12
    color: "#1e2430"
    opacity: 0.92
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    border.color: "#2e3545"; border.width: 1

    Column {
      anchors.fill: parent
      anchors.margins: 24
      spacing: 14

      Label {
        text: "Bienvenido"
        font.bold: true
        font.pixelSize: 22
        color: "#e6edf3"
      }

      TextField {
        id: userField
        placeholderText: "Usuario"
        font.pixelSize: 16
        color: "#e6edf3"
        selectionColor: "#4c566a"
        background: Rectangle { color: "#12151c"; radius: 6; border.color: "#2e3545" }
        text: sddm.lastUser || ""
      }

      TextField {
        id: passField
        placeholderText: "Contraseña"
        echoMode: TextInput.Password
        font.pixelSize: 16
        color: "#e6edf3"
        selectionColor: "#4c566a"
        background: Rectangle { color: "#12151c"; radius: 6; border.color: "#2e3545" }
      }

      Row {
        spacing: 12

        ComboBox {
          id: sessionCombo
          model: sddm.sessionModel
          textRole: "name"
          onActivated: {
            // No es obligatorio enviar el key si usamos defaultSession, pero permitimos elegir.
          }
          // Selecciona bspwm si existe
          Component.onCompleted: {
            for (var i=0;i<model.count;i++) {
              var item = model.get(i)
              if (item && item.name && item.name.toLowerCase().indexOf("bspwm") !== -1) {
                currentIndex = i; break;
              }
            }
          }
        }

        Button {
          id: loginBtn
          text: "Entrar"
          onClicked: {
            var sessionName = defaultSession
            if (sessionCombo.currentIndex >= 0) {
              var item = sessionCombo.model.get(sessionCombo.currentIndex)
              if (item && item.name) sessionName = item.name
            }
            sddm.login(userField.text, passField.text, sessionName)
          }
        }
      }

      Row {
        spacing: 12
        Button { text: "Reiniciar"; onClicked: sddm.reboot() }
        Button { text: "Apagar"; onClicked: sddm.powerOff() }
      }
    }
  }

  // Reloj simple y host en esquina inferior derecha
  Rectangle {
    color: "#00000000"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 20

    Column {
      spacing: 4
      Label { text: Qt.formatDateTime(new Date(), "ddd dd MMM yyyy") ; color: "#c7d0da" }
      Label { text: Qt.formatTime(new Date(), "HH:mm") ; font.pixelSize: 18; color: "#c7d0da" }
      Label { text: sddm.hostname ; color: "#8096ad" }
    }
  }
}
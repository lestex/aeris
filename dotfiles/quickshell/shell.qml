//
// AerisOS — first Quickshell bar.
//
// Deliberately minimal: ShellRoot and PanelWindow from Quickshell, everything
// else plain QtQuick. No compositor integration yet (workspaces, tray, audio)
// so that if this does not appear, the cause is the shell being wired up
// wrong rather than an API used incorrectly.
//
// Quickshell looks for ~/.config/quickshell/shell.qml by default, which is
// where setup.d/60-dotfiles.sh symlinks this.
//
// Live-reload: Quickshell watches its config, so editing this file (via
// bin/vm sync) should repaint the bar without restarting anything.
//
import Quickshell
import QtQuick

ShellRoot {
  PanelWindow {
    id: bar

    anchors {
      top: true
      left: true
      right: true
    }

    implicitHeight: 30
    color: "#161b23"

    // Accent hairline along the bottom, matching the Hyprland border colour.
    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: 1
      color: "#2b5b8c"
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 12
      text: "AerisOS"
      color: "#79b0e4"
      font.family: "JetBrains Mono"
      font.pixelSize: 12
      font.bold: true
    }

    Text {
      id: clock
      anchors.centerIn: parent
      color: "#e3e9ef"
      font.family: "JetBrains Mono"
      font.pixelSize: 12

      // Plain QtQuick rather than a Quickshell clock service: fewer types to
      // get wrong while establishing that the bar renders at all.
      function refresh() {
        clock.text = Qt.formatDateTime(new Date(), "ddd d MMM  HH:mm");
      }

      Component.onCompleted: clock.refresh()

      Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.refresh()
      }
    }
  }
}

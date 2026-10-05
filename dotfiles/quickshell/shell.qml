//
// AerisOS — themed Quickshell bar.
//
// Colours come from ~/.local/state/aerisos/current/colors.json, written by
// `aeris-theme set`. FileView watches the file, so switching themes repaints
// the bar with no restart.
//
// Quickshell looks for ~/.config/quickshell/shell.qml by default, which is
// where setup.d/60-dotfiles.sh symlinks this.
//
import Quickshell
import Quickshell.Io
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
    color: theme.background

    // The defaults double as the fallback. If colors.json is missing or
    // unparseable the bar still renders legibly, rather than coming up
    // black-on-black or not at all.
    QtObject {
      id: theme

      property color background: "#161b23"
      property color foreground: "#e3e9ef"
      property color accent: "#79b0e4"
      property color muted: "#475363"

      function apply(json) {
        try {
          const c = JSON.parse(json);
          if (c.background) theme.background = c.background;
          if (c.foreground) theme.foreground = c.foreground;
          if (c.accent) theme.accent = c.accent;
          if (c.muted) theme.muted = c.muted;
        } catch (e) {
          console.warn("aeris: colors.json did not parse:", e);
        }
      }
    }

    FileView {
      id: colorsFile

      path: Quickshell.env("HOME") + "/.local/state/aerisos/current/colors.json"

      // Read synchronously at startup so the bar never flashes its defaults,
      // then follow the file for later `aeris-theme set` runs.
      blockLoading: true
      watchChanges: true

      onLoaded: theme.apply(colorsFile.text())
      onFileChanged: colorsFile.reload()
      onLoadFailed: console.warn("aeris: no readable colors.json; using built-in defaults")
    }

    // Accent hairline along the bottom.
    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: 1
      color: theme.accent
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 12
      text: "AerisOS"
      color: theme.accent
      font.family: "JetBrains Mono"
      font.pixelSize: 12
      font.bold: true
    }

    Text {
      id: clock

      anchors.centerIn: parent
      color: theme.foreground
      font.family: "JetBrains Mono"
      font.pixelSize: 12

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

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: 12
      text: colorsFile.loaded ? "" : "no theme"
      color: theme.muted
      font.family: "JetBrains Mono"
      font.pixelSize: 11
    }
  }
}

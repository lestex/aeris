//
// AerisOS bar.
//
// Layout follows Omarchy's: menu and workspaces left, clock center, active
// window right. Colors come from ~/.local/state/aerisos/current/colors.json,
// written by `aeris-theme set`; FileView watches it so a theme switch
// repaints without a restart.
//
// Every Hyprland property used here was checked against Quickshell's source
// rather than assumed:
//   Hyprland.workspaces      ObjectModel, iterate .values
//   workspace.id/.focused/.urgent
//   Hyprland.activeToplevel  may be null; .title
//   Hyprland.dispatch(cmd)   for click-to-switch
//   Quickshell.execDetached([...])
//
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

ShellRoot {
  // Defaults double as the fallback: if colors.json is missing the bar
  // still renders legibly instead of black-on-black.
  QtObject {
    id: theme

    property color background: "#161b23"
    property color foreground: "#e3e9ef"
    property color accent: "#79b0e4"
    property color muted: "#475363"
    property color selection: "#223044"
    property color urgent: "#d9a55e"

    function apply(json) {
      try {
        const c = JSON.parse(json);
        if (c.background) theme.background = c.background;
        if (c.foreground) theme.foreground = c.foreground;
        if (c.accent) theme.accent = c.accent;
        if (c.muted) theme.muted = c.muted;
        if (c.selection) theme.selection = c.selection;
        if (c.red) theme.urgent = c.red;
      } catch (e) {
        console.warn("aeris: colors.json did not parse:", e);
      }
    }
  }

  // --- wallpaper -----------------------------------------------------------
  //
  // A layer-shell surface on the Background layer, so it sits behind every
  // window. ExclusionMode.Ignore keeps it from reserving screen space the way
  // the bar does.
  //
  // The path comes from ~/.local/state/aerisos/current/background, written as
  // plain text by `aeris-background`. An empty file means "no image", and the
  // solid theme color shows through — which is also what happens before you
  // have put any wallpapers on the machine.
  PanelWindow {
    id: wallpaper

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    color: theme.background

    property string imagePath: ""

    FileView {
      id: backgroundFile

      path: Quickshell.env("HOME") + "/.local/state/aerisos/current/background"
      blockLoading: true
      watchChanges: true
      printErrors: false

      onLoaded: wallpaper.imagePath = backgroundFile.text().trim()
      onFileChanged: backgroundFile.reload()
      onLoadFailed: wallpaper.imagePath = ""
    }

    Image {
      anchors.fill: parent
      source: wallpaper.imagePath ? "file://" + wallpaper.imagePath : ""
      visible: status === Image.Ready
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
    }
  }

  PanelWindow {
    id: bar

    anchors {
      top: true
      left: true
      right: true
    }

    implicitHeight: 30
    color: theme.background

    FileView {
      id: colorsFile

      path: Quickshell.env("HOME") + "/.local/state/aerisos/current/colors.json"
      blockLoading: true
      watchChanges: true

      onLoaded: theme.apply(colorsFile.text())
      onFileChanged: colorsFile.reload()
      onLoadFailed: console.warn("aeris: no readable colors.json; using defaults")
    }

    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: 1
      color: theme.accent
    }

    // --- left: menu button + workspaces -------------------------------------

    Row {
      id: left

      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 10

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "AerisOS"
        color: menuMouse.containsMouse ? theme.foreground : theme.accent
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        font.bold: true

        MouseArea {
          id: menuMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["aeris-menu"])
        }
      }

      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
          // .values is a plain list, so it can be sorted; the model's own
          // order is not guaranteed to be by id.
          model: {
            const ws = Hyprland.workspaces.values.slice();
            ws.sort((a, b) => a.id - b.id);
            return ws;
          }

          delegate: Rectangle {
            required property var modelData

            width: Math.max(20, label.implicitWidth + 12)
            height: 18
            radius: 4
            color: modelData.focused ? theme.accent
                 : modelData.urgent ? theme.urgent
                 : wsMouse.containsMouse ? theme.selection
                 : "transparent"

            Text {
              id: label
              anchors.centerIn: parent
              text: modelData.name
              color: modelData.focused ? theme.background : theme.foreground
              font.family: "JetBrains Mono"
              font.pixelSize: 11
            }

            MouseArea {
              id: wsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
          }
        }
      }
    }

    // --- center: clock ------------------------------------------------------

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

    // --- right: active window ------------------------------------------------

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      // Keep clear of the clock on a narrow screen.
      width: Math.min(implicitWidth, bar.width / 2 - 120)

      text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
      color: theme.muted
      elide: Text.ElideRight
      font.family: "JetBrains Mono"
      font.pixelSize: 11
    }
  }
}

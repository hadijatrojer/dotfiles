import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null

  IpcHandler {
    target: "swayShortcuts"

    function open() {
      if (!root.pluginApi)
        return;
      root.pluginApi.withCurrentScreen(screen => root.pluginApi.openLauncher(screen));
    }

    function close() {
      if (!root.pluginApi)
        return;
      root.pluginApi.withCurrentScreen(screen => root.pluginApi.closeLauncher(screen));
    }

    function toggle() {
      if (!root.pluginApi)
        return;
      root.pluginApi.withCurrentScreen(screen => root.pluginApi.toggleLauncher(screen));
    }
  }
}

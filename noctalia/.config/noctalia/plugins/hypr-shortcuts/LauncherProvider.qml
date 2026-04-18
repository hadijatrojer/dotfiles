import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var launcher: null
  property var pluginApi: null
  property string name: "Hypr Shortcuts"
  property string supportedLayouts: "list"
  property string iconMode: Settings.data.appLauncher.iconMode
  property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/hypr/hyprland.conf"
  property var binds: []
  property var searchIndex: []
  property bool bindsLoaded: false
  property string lastConfigText: ""

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    blockLoading: false

    onLoaded: root.reloadBindings()
    onFileChanged: root.reloadBindings()
  }

  function init() {
    reloadBindings();
  }

  function handleCommand(searchText) {
    return searchText.startsWith(">hypr");
  }

  function commands() {
    return [
      {
        "name": ">hypr",
        "description": "Show Hyprland keybindings",
        "icon": iconMode === "tabler" ? "keyboard" : "input-keyboard",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function () {
          launcher.setSearchText(">hypr ");
        }
      }
    ];
  }

  function reloadBindings() {
    const configText = String(configFile.text() || "");
    if (configText === lastConfigText && bindsLoaded)
      return;

    bindsLoaded = false;
    lastConfigText = configText;

    try {
      binds = parseBinds(configText);
      searchIndex = buildSearchIndex(binds);
      bindsLoaded = binds.length > 0;
    } catch (error) {
      binds = [];
      searchIndex = [];
    }
  }

  function parseBinds(configText) {
    if (!configText)
      return [];

    const variables = parseVariables(configText);
    const entries = [];
    const lines = configText.split(/\r?\n/);

    for (let i = 0; i < lines.length; i++) {
      const clean = stripComment(lines[i]).trim();
      if (!clean)
        continue;

      const match = clean.match(/^\s*(bind\w*)\s*=\s*(.+)$/);
      if (!match)
        continue;

      const bindKind = match[1].toLowerCase();
      const parts = match[2].split(",").map(part => substituteVars(part.trim(), variables));
      if (parts.length < 3)
        continue;

      let mods = "";
      let key = "";
      let action = "";
      let arg = "";
      let description = "";

      if (bindKind.startsWith("bindd") && parts.length >= 4) {
        mods = parts[0];
        key = parts[1];
        description = parts[2].trim();
        action = parts[3].trim();
        arg = parts.slice(4).join(",").trim();
      } else {
        mods = parts[0];
        key = parts[1];
        action = parts[2].trim();
        arg = parts.slice(3).join(",").trim();
        description = describeAction(action, arg);
      }

      const combo = normalizeCombo(mods, key);
      if (!combo)
        continue;

      entries.push({
        combo: combo,
        description: description || describeAction(action, arg),
        action: action,
        arg: arg
      });
    }

    return entries.sort((a, b) => {
      const comboCompare = a.combo.localeCompare(b.combo);
      if (comboCompare !== 0)
        return comboCompare;
      return a.description.localeCompare(b.description);
    });
  }

  function buildSearchIndex(entries) {
    return entries.map(entry => ({
      "combo": entry.combo,
      "description": entry.description,
      "action": entry.action,
      "arg": entry.arg,
      "searchText": (entry.combo + " " + entry.description + " " + entry.action + " " + entry.arg).toLowerCase()
    }));
  }

  function parseVariables(configText) {
    const vars = {};
    const lines = configText.split(/\r?\n/);

    for (let i = 0; i < lines.length; i++) {
      const clean = stripComment(lines[i]).trim();
      const match = clean.match(/^\$([A-Za-z0-9_-]+)\s*=\s*(.+)$/);
      if (match)
        vars[match[1]] = match[2].trim();
    }

    return vars;
  }

  function stripComment(line) {
    return line.split("#", 1)[0];
  }

  function substituteVars(text, variables) {
    return text.replace(/\$([A-Za-z0-9_-]+)/g, function (_, key) {
      return Object.prototype.hasOwnProperty.call(variables, key) ? variables[key] : "$" + key;
    });
  }

  function normalizeCombo(mods, key) {
    const tokens = mods.replace(/[|+]/g, " ").trim().split(/\s+/).filter(Boolean);
    if (key.trim())
      tokens.push(key.trim());
    return tokens.join(" + ");
  }

  function describeAction(action, arg) {
    const lowered = action.trim().toLowerCase();
    const trimmedArg = arg.trim();
    const moveMap = {
      "l": "left",
      "r": "right",
      "u": "up",
      "d": "down"
    };

    if (lowered === "workspace") {
      if (/^\d+$/.test(trimmedArg))
        return "Go to workspace " + trimmedArg;
      if (trimmedArg.startsWith("e+"))
        return "Next workspace";
      if (trimmedArg.startsWith("e-"))
        return "Previous workspace";
    }

    if (lowered === "movetoworkspace" && /^\d+$/.test(trimmedArg))
      return "Send window to workspace " + trimmedArg;

    if (lowered === "movefocus")
      return "Focus " + (moveMap[trimmedArg.toLowerCase()] || trimmedArg);

    if (lowered === "exec")
      return describeExec(trimmedArg);

    const actionMap = {
      "killactive": "Close window",
      "togglefloating": "Toggle floating",
      "togglesplit": "Toggle split layout",
      "movewindow": "Move window (drag)",
      "resizewindow": "Resize window (drag)",
      "pseudo": "Toggle pseudotile",
      "exit": "Exit Hyprland"
    };

    return actionMap[lowered] || (lowered + " " + trimmedArg).trim();
  }

  function describeExec(arg) {
    if (arg.includes("open-hypr-shortcuts.sh"))
      return "Show Hyprland shortcuts";
    if (arg.includes("$menu") || arg.startsWith("qs -c noctalia-shell ipc call launcher toggle"))
      return "App launcher";
    if (arg.includes("$terminal") || arg.startsWith("alacritty"))
      return "Open terminal";
    if (arg.includes("$fileManager") || arg.startsWith("nautilus"))
      return "Open file manager";
    if (arg.includes("playerctl"))
      return "Media control";
    if (arg.includes("wpctl"))
      return "Audio control";
    if (arg.includes("brightnessctl"))
      return "Brightness control";
    if (arg.includes("grim") || arg.includes("satty"))
      return "Screenshot";
    return "Run command";
  }

  function getResults(query) {
    if (!query.startsWith(">hypr"))
      return [];

    if (!bindsLoaded) {
      return [
        {
          "name": "Loading Hypr shortcuts",
          "description": "Waiting for " + configPath,
          "icon": "keyboard",
          "isTablerIcon": true,
          "isImage": false,
          "_score": 0,
          "provider": root
        }
      ];
    }

    let searchTerm = query.substring(5).trim();
    if (!searchTerm)
      return binds.map(entry => toLauncherItem(entry, 0));

    const matches = FuzzySort.go(searchTerm.toLowerCase(), searchIndex, {
      "keys": ["combo", "description", "searchText"],
      "limit": 40
    });

    return matches.map(match => toLauncherItem(match.obj, match.score));
  }

  function toLauncherItem(entry, score) {
    return {
      "name": entry.combo,
      "description": entry.description,
      "icon": "keyboard",
      "isTablerIcon": true,
      "isImage": false,
      "_score": score,
      "provider": root,
      "onActivate": createActivateHandler(entry.action, entry.arg)
    };
  }

  function createActivateHandler(action, arg) {
    return function () {
      if (launcher)
        launcher.close();

      Qt.callLater(() => {
        const command = ["hyprctl", "dispatch", action];
        if (arg)
          command.push(arg);
        Quickshell.execDetached(command);
      });
    };
  }
}

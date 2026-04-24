import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var launcher: null
  property var pluginApi: null
  property string name: "Sway Shortcuts"
  property string supportedLayouts: "list"
  property string iconMode: Settings.data.appLauncher.iconMode
  property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/sway/config"
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
    return searchText.startsWith(">sway");
  }

  function commands() {
    return [
      {
        "name": ">sway",
        "description": "Show Sway keybindings",
        "icon": iconMode === "tabler" ? "keyboard" : "input-keyboard",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function () {
          launcher.setSearchText(">sway ");
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
      if (!clean.startsWith("bindsym "))
        continue;

      const body = substituteVars(clean.substring(8).trim(), variables);
      const splitIndex = body.indexOf(" ");
      if (splitIndex === -1)
        continue;

      const combo = normalizeCombo(body.substring(0, splitIndex).trim());
      const command = body.substring(splitIndex + 1).trim();
      if (!combo || !command)
        continue;

      entries.push({
        combo: combo,
        displayCombo: formatCombo(combo),
        command: command,
        description: describeCommand(command)
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
      "displayCombo": entry.displayCombo,
      "command": entry.command,
      "description": entry.description,
      "searchText": (entry.combo + " " + entry.displayCombo + " " + entry.description + " " + entry.command).toLowerCase()
    }));
  }

  function parseVariables(configText) {
    const vars = {};
    const lines = configText.split(/\r?\n/);

    for (let i = 0; i < lines.length; i++) {
      const clean = stripComment(lines[i]).trim();
      const match = clean.match(/^set\s+\$([A-Za-z0-9_-]+)\s+(.+)$/);
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

  function normalizeCombo(combo) {
    return combo.replace(/\$/g, "");
  }

  function formatCombo(combo) {
    const aliases = {
      "mod1": "Alt",
      "mod4": "Start",
      "ctrl": "Ctrl",
      "control": "Ctrl",
      "shift": "Shift",
      "return": "Enter",
      "prior": "Page Up",
      "next": "Page Down",
      "space": "Space",
      "tab": "Tab",
      "left": "Left",
      "right": "Right",
      "up": "Up",
      "down": "Down",
      "bracketleft": "[",
      "bracketright": "]",
      "slash": "/",
      "minus": "-",
      "equal": "="
    };

    return combo.split("+").map(part => {
      const trimmed = part.trim();
      const key = trimmed.toLowerCase();
      if (Object.prototype.hasOwnProperty.call(aliases, key))
        return aliases[key];
      if (/^xf86/i.test(trimmed))
        return trimmed.replace(/^XF86/, "");
      if (trimmed.length === 1)
        return trimmed.toUpperCase();
      return trimmed;
    }).join(" + ");
  }

  function describeCommand(command) {
    if (command.startsWith("exec "))
      return describeExec(command.substring(5).trim());

    const lowered = command.toLowerCase();

    if (lowered.startsWith("workspace number "))
      return "Go to workspace " + command.substring(17).trim();
    if (lowered.startsWith("move container to workspace number "))
      return "Send window to workspace " + command.substring(33).trim();
    if (lowered === "focus left" || lowered === "focus right" || lowered === "focus up" || lowered === "focus down")
      return "Focus " + command.substring(6).trim();
    if (lowered === "move left" || lowered === "move right" || lowered === "move up" || lowered === "move down")
      return "Move window " + command.substring(5).trim();
    if (lowered.startsWith("resize set width "))
      return "Set width preset";
    if (lowered === "kill")
      return "Close window";
    if (lowered === "fullscreen toggle")
      return "Toggle fullscreen";
    if (lowered === "sticky toggle")
      return "Toggle sticky";
    if (lowered.startsWith("layout toggle"))
      return "Toggle layout";

    return command;
  }

  function describeExec(arg) {
    if (arg.includes("launcher toggle"))
      return "App launcher";
    if (arg.includes("launcher emoji"))
      return "Emoji picker";
    if (arg.includes("launcher clipboard"))
      return "Clipboard history";
    if (arg.includes("launcher windows"))
      return "Window picker";
    if (arg === "alacritty")
      return "Open terminal";
    if (arg.startsWith("nautilus"))
      return "Open file manager";
    if (arg.startsWith("google-chrome-stable"))
      return "Open browser";
    if (arg.includes("wpctl"))
      return "Audio control";
    if (arg.includes("brightnessctl"))
      return "Brightness control";
    if (arg.includes("playerctl"))
      return "Media control";
    if (arg.includes("grim") || arg.includes("satty"))
      return "Screenshot";
    return "Run command";
  }

  function getResults(query) {
    if (!query.startsWith(">sway"))
      return [];

    if (!bindsLoaded) {
      return [
        {
          "name": "Loading Sway shortcuts",
          "description": "Waiting for " + configPath,
          "icon": "keyboard",
          "isTablerIcon": true,
          "isImage": false,
          "_score": 0,
          "provider": root
        }
      ];
    }

    const searchTerm = query.substring(5).trim();
    if (!searchTerm)
      return binds.map(entry => toLauncherItem(entry, 0));

    const matches = FuzzySort.go(searchTerm.toLowerCase(), searchIndex, {
      "keys": ["combo", "displayCombo", "description", "searchText"],
      "limit": 40
    });

    return matches.map(match => toLauncherItem(match.obj, match.score));
  }

  function toLauncherItem(entry, score) {
    return {
      "name": entry.displayCombo,
      "description": entry.description,
      "icon": "keyboard",
      "isTablerIcon": true,
      "isImage": false,
      "_score": score,
      "provider": root,
      "onActivate": createActivateHandler(entry.command)
    };
  }

  function createActivateHandler(command) {
    return function () {
      if (launcher)
        launcher.close();

      Qt.callLater(() => {
        if (command.startsWith("exec ")) {
          Quickshell.execDetached(["sh", "-lc", command.substring(5).trim()]);
          return;
        }

        Quickshell.execDetached(["swaymsg", command]);
      });
    };
  }
}

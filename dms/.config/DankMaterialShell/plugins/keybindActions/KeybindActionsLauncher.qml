import QtQuick
import Quickshell
import qs.Common
import qs.Services

Item {
    id: root

    property var pluginService: null
    property string trigger: "?"
    property var entries: []
    property bool refreshInFlight: false

    signal itemsChanged

    Component.onCompleted: {
        if (pluginService) {
            trigger = pluginService.loadPluginData("keybindActions", "trigger", "?");
        }
        refreshEntries();
    }

    Timer {
        id: refreshTimer
        interval: 4000
        repeat: true
        running: true
        onTriggered: root.refreshEntries()
    }

    function getItems(query) {
        if (!entries.length && !refreshInFlight) {
            refreshEntries();
        }

        const trimmedQuery = (query || "").trim().toLowerCase();
        const filtered = trimmedQuery.length === 0 ? entries : entries.filter(entry => {
            return entry.name.toLowerCase().includes(trimmedQuery)
                || entry.comment.toLowerCase().includes(trimmedQuery)
                || entry.key.toLowerCase().includes(trimmedQuery);
        });

        return filtered.slice(0, 80).map(entry => {
            return {
                name: entry.name,
                icon: entry.icon,
                comment: entry.comment,
                action: entry.action,
                execKind: entry.execKind,
                categories: ["Keybind Actions"]
            };
        });
    }

    function executeItem(item) {
        if (!item || !item.action) {
            return;
        }

        if (item.execKind === "shell") {
            Quickshell.execDetached(["sh", "-lc", item.action]);
            return;
        }

        if (item.execKind === "sway") {
            Quickshell.execDetached(["swaymsg", item.action]);
        }
    }

    function refreshEntries() {
        if (refreshInFlight) {
            return;
        }

        refreshInFlight = true;
        Proc.runCommand("keybindActionsShow", ["dms", "keybinds", "show", "sway"], function (stdout, exitCode) {
            refreshInFlight = false;

            if (exitCode !== 0 || !stdout) {
                return;
            }

            try {
                const payload = JSON.parse(stdout);
                entries = transformBinds(payload.binds || {});
                itemsChanged();
            } catch (error) {
                console.warn("keybindActions: failed to parse keybinds:", error);
            }
        }, 0, 4000);
    }

    function transformBinds(groups) {
        const nextEntries = [];

        for (const sectionName in groups) {
            const section = groups[sectionName] || [];
            for (let i = 0; i < section.length; i++) {
                const bind = section[i];
                if (shouldHideBind(bind)) {
                    continue;
                }
                const parsed = normalizeAction(bind.action || "");
                if (!parsed) {
                    continue;
                }

                nextEntries.push({
                    key: prettifyKey(bind.key || ""),
                    name: prettifyKey(bind.key || "") + "  " + (bind.desc || parsed.action),
                    comment: sectionName + "  " + parsed.preview,
                    action: parsed.action,
                    execKind: parsed.execKind,
                    icon: parsed.icon
                });
            }
        }

        nextEntries.sort((a, b) => a.key.localeCompare(b.key));
        return nextEntries;
    }

    function shouldHideBind(bind) {
        const key = bind.key || "";
        const action = (bind.action || "").trim();

        if (key === "Mod4+Shift+slash" || key === "Mod4+space" || key === "Mod4+Tab") {
            return true;
        }

        if (key === "Ctrl+Alt+Delete" || action === "kill") {
            return true;
        }

        if (action === "exec dms ipc launcher toggle" || action === "exec dms ipc launcher toggleQuery '?'" || action === "exec dms ipc launcher toggleQuery ';'") {
            return true;
        }

        if (action === "exec ~/.config/sway/scripts/session-quit") {
            return true;
        }

        return false;
    }

    function normalizeAction(action) {
        const trimmed = (action || "").trim();
        if (!trimmed) {
            return null;
        }

        if (trimmed === "kill") {
            return null;
        }

        if (trimmed.startsWith("exec ")) {
            return {
                action: trimmed.substring(5),
                execKind: "shell",
                preview: trimmed.substring(5),
                icon: "play_arrow"
            };
        }

        return {
            action: trimmed,
            execKind: "sway",
            preview: trimmed,
            icon: "keyboard_command_key"
        };
    }

    function prettifyKey(key) {
        return (key || "")
            .replaceAll("Mod4", "Start")
            .replaceAll("Mod1", "Alt")
            .replaceAll("Control", "Ctrl")
            .replaceAll("Page_Down", "PageDown")
            .replaceAll("Page_Up", "PageUp")
            .replaceAll("XF86AudioRaiseVolume", "AudioRaise")
            .replaceAll("XF86AudioLowerVolume", "AudioLower")
            .replaceAll("XF86AudioMute", "AudioMute")
            .replaceAll("XF86AudioMicMute", "MicMute")
            .replaceAll("XF86AudioPlay", "AudioPlay")
            .replaceAll("XF86AudioPause", "AudioPause")
            .replaceAll("XF86AudioStop", "AudioStop")
            .replaceAll("XF86AudioNext", "AudioNext")
            .replaceAll("XF86AudioPrev", "AudioPrev")
            .replaceAll("XF86MonBrightnessUp", "BrightnessUp")
            .replaceAll("XF86MonBrightnessDown", "BrightnessDown");
    }

    onTriggerChanged: {
        if (pluginService) {
            pluginService.savePluginData("keybindActions", "trigger", trigger);
        }
    }
}

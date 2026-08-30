import QtQuick
import Quickshell
import qs.Common
import qs.Services

Item {
    id: root

    property var pluginService: null
    property string trigger: ";"
    property var windows: []
    property bool refreshInFlight: false

    signal itemsChanged

    Component.onCompleted: {
        if (pluginService) {
            trigger = pluginService.loadPluginData("windowSwitcher", "trigger", ";");
        }
    }

    function getItems(query) {
        if (!refreshInFlight) {
            refreshWindows();
        }

        const trimmedQuery = (query || "").trim().toLowerCase();
        const filtered = trimmedQuery.length === 0 ? windows : windows.filter(window => {
            return window.name.toLowerCase().includes(trimmedQuery)
                || window.comment.toLowerCase().includes(trimmedQuery);
        });

        return filtered.slice(0, 50).map(window => {
            return {
                name: window.name,
                icon: window.icon,
                comment: window.comment,
                action: "focus:" + window.id,
                categories: ["Window Switcher"]
            };
        });
    }

    function executeItem(item) {
        if (!item || !item.action || !item.action.startsWith("focus:")) {
            return;
        }

        const windowId = item.action.substring("focus:".length);
        if (!windowId) {
            return;
        }

        Quickshell.execDetached(["swaymsg", "[con_id=" + windowId + "]", "focus"]);
    }

    function refreshWindows() {
        if (refreshInFlight) {
            return;
        }

        refreshInFlight = true;
        Proc.runCommand("windowSwitcherTree", ["swaymsg", "-t", "get_tree", "-r"], function (stdout, exitCode) {
            refreshInFlight = false;

            if (exitCode !== 0 || !stdout) {
                return;
            }

            try {
                const tree = JSON.parse(stdout);
                windows = flattenTree(tree);
                itemsChanged();
            } catch (error) {
                console.warn("windowSwitcher: failed to parse sway tree:", error);
            }
        }, 0, 4000);
    }

    function flattenTree(rootNode) {
        const collected = [];
        const focusedIds = [];

        function visit(node) {
            if (!node) {
                return;
            }

            const childNodes = []
                .concat(node.nodes || [])
                .concat(node.floating_nodes || []);

            const hasChildren = childNodes.length > 0;
            const hasWindow = node.pid || node.app_id || (node.window_properties && node.window_properties.class);

            if (hasWindow && !hasChildren) {
                const appId = node.app_id
                    || (node.window_properties && node.window_properties.class)
                    || "unknown";
                const title = node.name || "untitled";
                const marker = node.focused ? "•" : "·";

                collected.push({
                    id: String(node.id),
                    name: title,
                    comment: marker + " " + appId,
                    icon: "select_window",
                    focused: !!node.focused
                });
            }

            for (let i = 0; i < childNodes.length; i++) {
                visit(childNodes[i]);
            }
        }

        visit(rootNode);

        buildFocusOrder(rootNode, focusedIds);

        const rankById = {};
        for (let i = 0; i < focusedIds.length; i++) {
            rankById[String(focusedIds[i])] = i;
        }

        collected.sort((a, b) => {
            const aRank = rankById[a.id];
            const bRank = rankById[b.id];
            const aHasRank = aRank !== undefined;
            const bHasRank = bRank !== undefined;

            if (a.focused && !b.focused)
                return 1;
            if (!a.focused && b.focused)
                return -1;

            if (aHasRank && bHasRank)
                return aRank - bRank;
            if (aHasRank)
                return -1;
            if (bHasRank)
                return 1;
            return a.name.localeCompare(b.name);
        });

        return collected;
    }

    function buildFocusOrder(rootNode, focusedIds) {
        function walk(node) {
            if (!node) {
                return;
            }

            const childNodes = []
                .concat(node.nodes || [])
                .concat(node.floating_nodes || []);
            const byId = {};

            for (let i = 0; i < childNodes.length; i++) {
                byId[String(childNodes[i].id)] = childNodes[i];
            }

            const orderedIds = (node.focus || []).map(id => String(id));
            const seen = {};

            for (let i = 0; i < orderedIds.length; i++) {
                const child = byId[orderedIds[i]];
                if (!child) {
                    continue;
                }
                seen[orderedIds[i]] = true;
                walk(child);
            }

            for (let i = 0; i < childNodes.length; i++) {
                const child = childNodes[i];
                const childId = String(child.id);
                if (seen[childId]) {
                    continue;
                }
                walk(child);
            }

            const hasChildren = childNodes.length > 0;
            const hasWindow = node.pid || node.app_id || (node.window_properties && node.window_properties.class);
            if (hasWindow && !hasChildren) {
                focusedIds.push(node.id);
            }
        }

        walk(rootNode);
    }

    onTriggerChanged: {
        if (pluginService) {
            pluginService.savePluginData("windowSwitcher", "trigger", trigger);
        }
    }
}

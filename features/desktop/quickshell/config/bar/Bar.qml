import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool shown: false

    UsageService { id: usageService }
    MonitorModes { id: monitorModes }

    IpcHandler {
        target: "bar"

        function toggle(): void { root.shown = !root.shown; }
        function show(): void { root.shown = true; }
        function hide(): void { root.shown = false; }
        function refreshUsage(): void { usageService.refresh(); }
        function usage(): string { return JSON.stringify(usageService.usage); }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            BarWindow {
                required property var modelData
                screen: modelData
                shown: root.shown
                hugeMargins: monitorModes.enabledFor(modelData)
                usage: usageService.usage
                refreshUsage: () => usageService.refresh()
            }
        }
    }
}

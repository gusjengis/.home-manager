pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    readonly property color background: "#151922"
    readonly property color surface: "#202633"
    readonly property color surfaceHover: "#2a3242"
    readonly property color text: "#e8edf5"
    readonly property color muted: "#8d99aa"
    readonly property color accent: "#8ec5ff"
    readonly property color accentStrong: "#5aa7f7"
    readonly property color warning: "#f2c879"
    readonly property color danger: "#ef8d8d"
    readonly property color border: "#344052"

    readonly property int barHeight: 40
    readonly property int radius: 8
    readonly property int spacing: 8
    readonly property int fontSize: 13
    readonly property string fontFamily: "sans-serif"

    property int windowBorderWidth: 2
    property int windowRadius: 16
    property color windowBorder: "#aa595959"

    function refreshHyprland() {
        if (!borderWidthRequest.running)
            borderWidthRequest.running = true;
        if (!radiusRequest.running)
            radiusRequest.running = true;
        if (!borderColorRequest.running)
            borderColorRequest.running = true;
    }

    property var borderWidthRequest: Process {
        id: borderWidthRequest
        command: ["hyprctl", "-j", "getoption", "general:border_size"]
        stdout: StdioCollector { id: borderWidthOutput }
        onExited: (code, status) => {
            if (code === 0 && status === 0)
                windowBorderWidth = JSON.parse(borderWidthOutput.text).int;
        }
    }

    property var radiusRequest: Process {
        id: radiusRequest
        command: ["hyprctl", "-j", "getoption", "decoration:rounding"]
        stdout: StdioCollector { id: radiusOutput }
        onExited: (code, status) => {
            if (code === 0 && status === 0)
                windowRadius = JSON.parse(radiusOutput.text).int;
        }
    }

    property var borderColorRequest: Process {
        id: borderColorRequest
        command: ["hyprctl", "-j", "getoption", "general:col.inactive_border"]
        stdout: StdioCollector { id: borderColorOutput }
        onExited: (code, status) => {
            if (code !== 0 || status !== 0)
                return;
            const gradient = JSON.parse(borderColorOutput.text).gradient.split(" ")[0];
            windowBorder = "#" + gradient;
        }
    }

    property var hyprlandRefresh: Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: refreshHyprland()
    }
}

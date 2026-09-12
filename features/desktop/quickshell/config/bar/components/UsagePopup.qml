import QtQuick
import Quickshell
import "../../theme"

PopupWindow {
    id: popup

    required property var usage

    function provider(name) {
        const providers = usage.providers || [];
        return providers.find(item => item.name === name)
            || { "name": name, "available": false, "error": "loading", "windows": [] };
    }

    function toggle(anchorItem) {
        if (visible) {
            visible = false;
            return;
        }
        anchor.item = anchorItem;
        visible = true;
    }

    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 6
    implicitWidth: 390
    implicitHeight: 346
    color: "transparent"
    grabFocus: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.windowRadius
        color: Theme.background
        border { width: Theme.windowBorderWidth; color: Theme.windowBorder }
    }

    Column {
        anchors { fill: parent; margins: 14 }
        spacing: 10

        Text {
            text: "AI usage"
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 16; bold: true }
        }

        Text {
            text: "Subscription limits"
            color: Theme.muted
            font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 1 }
        }

        UsageProvider {
            width: parent.width
            provider: popup.provider("Claude")
            accentColor: Theme.warning
        }

        UsageProvider {
            width: parent.width
            provider: popup.provider("OpenAI")
            accentColor: Theme.accentStrong
        }
    }

    Shortcut { sequence: "Escape"; onActivated: popup.visible = false }
}

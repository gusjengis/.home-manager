import QtQuick
import "../../theme"

Rectangle {
    id: root

    required property var provider
    required property color accentColor

    // Render whatever numbers exist, including cached ones from a failed
    // refresh. Showing 0% for a failed fetch reads as "no usage", which is a
    // lie; the status line says why the numbers are old instead.
    readonly property bool hasData: provider.windows && provider.windows.length > 0

    function usageWindow(index, label) {
        return root.hasData && provider.windows[index]
            ? provider.windows[index]
            : { "label": label, "used": null, "reset": null };
    }

    function status() {
        if (!provider.error)
            return "";
        return root.hasData ? "stale · " + provider.error : provider.error;
    }

    implicitHeight: 125
    radius: Theme.radius
    color: Theme.surface
    border { width: 1; color: Theme.border }

    Text {
        id: providerName
        anchors { left: parent.left; leftMargin: 11; top: parent.top; topMargin: 9 }
        text: root.provider.name
        color: root.accentColor
        font { family: Theme.fontFamily; pixelSize: 14; bold: true }
    }

    Text {
        anchors { right: parent.right; rightMargin: 11; verticalCenter: providerName.verticalCenter }
        text: root.status()
        color: root.hasData ? Theme.muted : Theme.danger
        font { family: Theme.fontFamily; pixelSize: Theme.fontSize - 2 }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: providerName.bottom
            leftMargin: 11
            rightMargin: 11
            topMargin: 6
        }
        spacing: 7

        UsageWindow {
            width: parent.width
            usage: root.usageWindow(0, "5h")
            title: "5-hour window"
            accentColor: root.accentColor
        }

        UsageWindow {
            width: parent.width
            usage: root.usageWindow(1, "7d")
            title: "Weekly window"
            accentColor: root.accentColor
        }
    }
}

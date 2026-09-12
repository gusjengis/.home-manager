import QtQuick
import Quickshell
import "../../theme"

Rectangle {
    implicitWidth: label.implicitWidth + 18
    implicitHeight: 28
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.border

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
        color: Theme.text
        font { family: Theme.fontFamily; pixelSize: Theme.fontSize; bold: true }
    }
}

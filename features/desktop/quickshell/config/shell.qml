import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// QuickShell launcher shell. Two dedicated popups: a local application launcher
// and a remote launcher (Tailnet host picker, then applications on a chosen
// host). The UI lives in Launcher.qml (and its RequestProcess.qml /
// LaunchProcess.qml helpers).
ShellRoot {
    id: root
    property color backgroundColor: "#222222"
    property color textColor: "#ffffff"

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            if (localLauncher.visible)
                localLauncher.visible = false;
            else
                localLauncher.open("local");
        }
        function remote(): void {
            remoteLauncher.open("hosts");
        }
        function failure(message: string): void {
            remoteLauncher.error = message;
            remoteLauncher.visible = true;
        }
    }

    Launcher {
        id: localLauncher
        initialMode: "local"
        backgroundColor: root.backgroundColor
        textColor: root.textColor
    }

    Launcher {
        id: remoteLauncher
        initialMode: "hosts"
        backgroundColor: root.backgroundColor
        textColor: root.textColor
    }
}
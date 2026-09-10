import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// Application launcher popup. Dedicated to one flow, chosen at instantiation:
//   local  - desktop entries on this machine
//   hosts  - Tailnet machines to pick from, then remote applications
//
// The local and remote launchers are separate instances of this component in
// shell.qml, each bound to its own keyboard shortcut; nothing here switches
// between them.
PanelWindow {
    id: launcher
    required property color backgroundColor
    required property color textColor
    property string initialMode: "local"
    visible: false
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 560
    implicitHeight: 460
    color: backgroundColor

    property string mode: initialMode
    property var host: null
    property var entries: []
    property var request: null
    property string error: ""
    readonly property bool loading: request !== null
    readonly property var apps: mode === "local"
        ? DesktopEntries.applications.values.filter(a => !a.noDisplay) : entries
    readonly property var results: apps.filter(a =>
        (a.name + " " + (a.description || "")).toLowerCase().includes(search.text.toLowerCase()))

    function cancelRequest() {
        if (request) {
            const previous = request;
            request = null;
            previous.destroy();
        }
    }
    function reset(nextMode) {
        cancelRequest();
        mode = nextMode;
        entries = [];
        error = "";
        search.text = "";
        list.currentIndex = 0;
        visible = true;
        search.forceActiveFocus();
    }
    function open(nextMode) {
        reset(nextMode);
        if (nextMode === "hosts") {
            host = null;
            load(["hosts"]);
        } else if (nextMode === "remote" && host) {
            load(["list", host.id]);
        }
    }
    function load(args) {
        // Separate requests keep cancelled replies from replacing a newer list.
        request = RequestProcess.createObject(launcher, {
            command: ["quickshell-remote-apps"].concat(args),
            launcher: launcher
        });
        request.running = true;
    }
    function activate(index) {
        const app = results[index];
        if (!app || loading)
            return;
        if (mode === "hosts") {
            host = app;
            open("remote");
        } else if (mode === "local") {
            app.execute();
            visible = false;
        } else {
            const process = LaunchProcess.createObject(launcher, {
                command: ["quickshell-remote-apps", "start", host.id, app.id],
                appName: app.name, hostName: host.name,
                launcher: launcher
            });
            process.running = true;
            visible = false;
        }
    }

    // While visible, keep keyboard focus even when the pointer is elsewhere;
    // a click outside clears the grab and dismisses the launcher.
    HyprlandFocusGrab {
        id: focusGrab
        windows: [launcher]
        onCleared: launcher.visible = false
    }
    onVisibleChanged: {
        if (visible) {
            focusGrab.active = true;
            search.forceActiveFocus();
        } else {
            focusGrab.active = false;
            cancelRequest();
        }
    }

    Timer {
        interval: 35000
        running: launcher.loading
        onTriggered: {
            launcher.cancelRequest();
            launcher.error = "Request timed out. Check SSH access and rebuild both machines.";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
            Layout.fillWidth: true
            visible: launcher.mode !== "local"
            text: launcher.mode === "hosts"
                ? "Choose a Tailnet machine" : "Applications on " + launcher.host.name
            textFormat: Text.PlainText
            color: textColor
            elide: Text.ElideRight
            font.pixelSize: 18
        }

        TextField {
            id: search
            Layout.fillWidth: true
            placeholderText: launcher.mode === "hosts" ? "Search machines" : "Search applications"
            focus: true
            onTextChanged: list.currentIndex = 0
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onEscapePressed: launcher.visible = false
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier)) {
                    if (launcher.mode === "remote")
                        launcher.open("hosts");
                    else if (launcher.mode === "hosts")
                        launcher.visible = false;
                    event.accepted = true;
                }
            }
            onAccepted: launcher.activate(list.currentIndex)
        }

        Text {
            Layout.fillWidth: true
            visible: launcher.loading || launcher.error !== "" || launcher.results.length === 0
            text: launcher.loading ? "Loading..." : launcher.error || "No matches"
            textFormat: Text.PlainText
            color: launcher.error ? "#ffb4ab" : "#aaaaaa"
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: launcher.results
            currentIndex: 0
            highlightMoveDuration: 0
            highlight: Rectangle { color: "#333333"; radius: 4 }
            delegate: Item {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 52
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 10
                    IconImage {
                        source: modelData.iconData || Quickshell.iconPath(modelData.icon || "computer", true)
                        implicitSize: 32
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            textFormat: Text.PlainText
                            color: textColor
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.description || ""
                            textFormat: Text.PlainText
                            color: "#aaaaaa"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: launcher.activate(index)
                }
            }
        }

        Text {
            text: launcher.mode === "local"
                ? "Enter: launch    Esc: close"
                : "Enter: launch/select    Alt+Left: back    Esc: close"
            color: "#aaaaaa"
            font.pixelSize: 11
        }
    }
}
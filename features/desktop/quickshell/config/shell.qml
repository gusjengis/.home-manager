import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

ShellRoot {
    id: root
    property color backgroundColor: "#222222"
    property color textColor: "#ffffff"

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            if (launcher.visible && launcher.mode === "local")
                launcher.visible = false;
            else
                launcher.openLocal();
        }
        function remote(): void { launcher.openHosts(); }
        function failure(message: string): void {
            launcher.error = message;
            launcher.visible = true;
        }
    }

    // Separate requests keep cancelled replies from replacing a newer list.
    Component {
        id: requestComponent
        Process {
            id: request
            property bool didStart: false
            onStarted: didStart = true
            onRunningChanged: {
                if (!running && !didStart && launcher.request === request) {
                    launcher.request = null;
                    launcher.error = "Cannot start remote helper. Run rehome on this machine.";
                    request.destroy();
                }
            }
            stdout: StdioCollector { id: output }
            stderr: StdioCollector { id: errors }
            onExited: (code, status) => {
                if (launcher.request === request) {
                    launcher.request = null;
                    if (code !== 0 || status !== 0) {
                        launcher.error = errors.text.trim() || "Request failed. Check SSH access and rebuild both machines.";
                    } else {
                        try {
                            const entries = JSON.parse(output.text);
                            if (!Array.isArray(entries))
                                throw new Error("Expected an application list");
                            launcher.entries = entries;
                        } catch (e) {
                            launcher.error = "Invalid remote response: " + e.message;
                        }
                    }
                }
                request.destroy();
            }
        }
    }

    Component {
        id: launchComponent
        Process {
            id: launch
            property bool didStart: false
            onStarted: didStart = true
            onRunningChanged: {
                if (!running && !didStart) {
                    launcher.error = "Cannot start remote helper. Run rehome on this machine.";
                    launcher.visible = true;
                    launch.destroy();
                }
            }
            property string appName
            property string hostName
            stderr: StdioCollector { id: launchErrors }
            onExited: (code, status) => {
                if (code !== 0 || status !== 0) {
                    launcher.error = appName + " on " + hostName + ": " + (launchErrors.text.trim() || "Remote launch failed");
                    launcher.visible = true;
                }
                launch.destroy();
            }
        }
    }

    PanelWindow {
        id: launcher
        visible: false
        focusable: true
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 560
        implicitHeight: 460
        color: root.backgroundColor

        property string mode: "local"
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
        function load(args) {
            request = requestComponent.createObject(root, {command: ["quickshell-remote-apps"].concat(args)});
            request.running = true;
        }
        function openLocal() {
            reset("local");
            host = null;
        }
        function openHosts() {
            reset("hosts");
            host = null;
            load(["hosts"]);
        }
        function openApps(selectedHost) {
            host = selectedHost;
            reset("remote");
            load(["list", host.id]);
        }
        function activate(index) {
            const app = results[index];
            if (!app || loading)
                return;
            if (mode === "hosts") {
                openApps(app);
            } else if (mode === "local") {
                app.execute();
                visible = false;
            } else {
                const process = launchComponent.createObject(root, {
                    command: ["quickshell-remote-apps", "start", host.id, app.id],
                    appName: app.name, hostName: host.name
                });
                process.running = true;
                visible = false;
            }
        }

        onVisibleChanged: {
            if (visible)
                search.forceActiveFocus();
            else
                cancelRequest();
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

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Local"
                    highlighted: launcher.mode === "local"
                    onClicked: launcher.openLocal()
                }
                Button {
                    text: "Remote"
                    highlighted: launcher.mode !== "local"
                    onClicked: launcher.openHosts()
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Refresh"
                    visible: launcher.mode !== "local"
                    onClicked: launcher.mode === "hosts" ? launcher.openHosts() : launcher.openApps(launcher.host)
                }
            }

            Text {
                Layout.fillWidth: true
                text: launcher.mode === "local" ? "Applications" : launcher.mode === "hosts"
                    ? "Choose a Tailnet machine" : "Applications on " + launcher.host.name
                textFormat: Text.PlainText
                color: root.textColor
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
                        launcher.mode === "remote" ? launcher.openHosts() : launcher.openLocal();
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
                                color: root.textColor
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
                text: "Enter: launch/select    Alt+Left: back    Esc: close"
                color: "#aaaaaa"
                font.pixelSize: 11
            }
        }
    }
}

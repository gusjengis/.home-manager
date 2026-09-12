import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: service

    property var usage: ({
        "providers": [
            { "name": "Claude", "available": false, "error": "loading", "windows": [] },
            { "name": "OpenAI", "available": false, "error": "loading", "windows": [] }
        ]
    })

    function refresh() {
        if (!request.running)
            request.running = true;
    }

    Process {
        id: request
        command: ["quickshell-ai-usage"]
        stdout: StdioCollector { id: output }

        onExited: (code, status) => {
            if (code !== 0 || status !== 0)
                return;
            try {
                service.usage = JSON.parse(output.text);
            } catch (error) {
                console.warn("Cannot parse AI usage:", error);
            }
        }
    }

    Timer {
        // Anthropic rate-limits this endpoint; 5 minutes plus every shell
        // restart was enough to earn HTTP 429.
        interval: 900000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: service.refresh()
    }
}

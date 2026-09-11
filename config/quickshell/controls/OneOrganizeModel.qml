import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: root

    property bool visible: false
    property bool busy: false
    property bool online: true
    property string employee: "Mr. Rahul Jangir"
    property bool clockedIn: false
    property bool clockedOut: false
    property string clockInTime: ""
    property string clockOutTime: ""
    property string clockInRaw: ""
    property string clockOutRaw: ""
    property string projectName: "SDV Platform"
    property string projectId: "2"
    property int workedSeconds: 0
    property string workedDuration: "00:00:00"
    property string workedDurationShort: "0m"
    property string statusText: "Checking..."
    property string message: ""
    property string taskText: "Completed scheduled development tasks, code review, bug fixes, and daily progress reporting."

    function toggle() {
        if (root.visible) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        root.visible = true;
        root.refresh();
    }

    function close() {
        root.visible = false;
    }

    function refresh() {
        if (!statusProcess.running) {
            statusProcess.running = true;
        }
    }

    function clockIn() {
        if (root.busy) return;
        root.busy = true;
        root.message = "Clocking in...";
        actionProcess.command = ["oneorganize-status", "clockin"];
        actionProcess.running = true;
    }

    function clockOut(task) {
        if (root.busy) return;
        root.busy = true;
        root.message = "Clocking out (SDV Platform)...";
        const t = task && task.trim().length >= 50 ? task.trim() : root.taskText;
        actionProcess.command = ["oneorganize-status", "clockout", t];
        actionProcess.running = true;
    }

    function openPortal() {
        portalProcess.running = true;
    }

    function parseStatus(text) {
        if (!text || text.length === 0) return;
        try {
            const data = JSON.parse(text);
            root.online = !!data.ok;
            if (data.employee) root.employee = data.employee;
            root.clockedIn = !!data.is_clocked_in;
            root.clockedOut = !!data.is_clocked_out;
            root.clockInTime = data.clock_in_text || "";
            root.clockOutTime = data.clock_out_text || "";
            root.clockInRaw = data.clock_in_raw || "";
            root.clockOutRaw = data.clock_out_raw || "";
            root.projectName = data.project_name || "SDV Platform";
            root.projectId = data.project_id || "2";
            root.workedSeconds = data.elapsed_seconds || 0;
            root.updateWorkedDisplay();

            if (root.clockedIn && !root.clockedOut) {
                root.statusText = "Clocked In (" + (root.clockInTime || root.clockInRaw) + ")";
            } else if (root.clockedIn && root.clockedOut) {
                root.statusText = "Clocked Out (" + (root.clockOutTime || root.clockOutRaw) + ")";
            } else {
                root.statusText = "Not Clocked In";
            }
        } catch (e) {
            root.statusText = "Status Unavailable";
        }
    }

    function updateWorkedDisplay() {
        const total = Math.max(0, root.workedSeconds);
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        const pad = function(n) { return (n < 10 ? "0" + n : "" + n); };
        root.workedDuration = pad(h) + ":" + pad(m) + ":" + pad(s);
        if (h > 0) {
            root.workedDurationShort = h + "h " + pad(m) + "m";
        } else {
            root.workedDurationShort = m + "m";
        }
    }

    Timer {
        id: liveTickTimer
        interval: 1000
        running: root.clockedIn && !root.clockedOut
        repeat: true
        onTriggered: {
            root.workedSeconds += 1;
            root.updateWorkedDisplay();
        }
    }

    Timer {
        id: autoRefreshTimer
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess
        command: ["oneorganize-status", "json"]
        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(this.text.trim())
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = this.text.trim();
                if (err.length > 0 && !root.clockedIn) {
                    root.message = err;
                }
            }
        }
    }

    Process {
        id: actionProcess
        command: ["sh", "-c", "exit 0"]
        onRunningChanged: {
            if (!running && root.busy) {
                root.busy = false;
                root.refresh();
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();
                if (out.length > 0) {
                    root.message = out.split("\n")[0];
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = this.text.trim();
                if (err.length > 0) {
                    root.message = err.split("\n")[0];
                }
            }
        }
    }

    Process {
        id: portalProcess
        command: ["oneorganize-status", "open"]
    }

    Component.onCompleted: {
        root.refresh();
    }
}

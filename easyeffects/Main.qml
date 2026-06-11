import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

// AIDEV-NOTE: Main logic singleton for Easy Effects Profile Switcher.
// All Process instances live here; BarWidget and Panel access state via pluginApi.mainInstance.
Item {
    id: root

    property var pluginApi: null

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    // ─── Profile state ───
    property var outputProfiles: []
    property var inputProfiles: []

    property int currentOutputIndex: cfg.currentOutputIndex ?? defaults.currentOutputIndex ?? -1
    property int currentInputIndex: cfg.currentInputIndex ?? defaults.currentInputIndex ?? -1

    readonly property string currentOutputProfile: currentOutputIndex >= 0 && currentOutputIndex < outputProfiles.length
        ? outputProfiles[currentOutputIndex] : "None"
    readonly property string currentInputProfile: currentInputIndex >= 0 && currentInputIndex < inputProfiles.length
        ? inputProfiles[currentInputIndex] : "None"

    property bool profilesLoaded: false
    property string activeOutputProfile: ""
    property string activeInputProfile: ""

    Component.onCompleted: loadProfiles.running = true

    // ─── Public API for BarWidget / Panel ───
    function refreshProfiles() {
        loadProfiles.running = true
    }

    function syncActiveProfile() {
        root.activeOutputProfile = ""
        root.activeInputProfile = ""
        checkActiveOutput.running = true
    }

    function loadOutputProfile(index) {
        root.currentOutputIndex = index
        _persistIndices(index, root.currentInputIndex)
        var profileName = root.outputProfiles[index]
        switchProfileCommand.command = ["sh", "-c", "easyeffects -l \"" + profileName + "\""]
        checkInstalled.running = true
    }

    function loadInputProfile(index) {
        root.currentInputIndex = index
        _persistIndices(root.currentOutputIndex, index)
        var profileName = root.inputProfiles[index]
        switchProfileCommand.command = ["sh", "-c", "easyeffects -l \"" + profileName + "\""]
        checkInstalled.running = true
    }

    function resetAllProfiles() {
        root.currentOutputIndex = -1
        root.currentInputIndex = -1
        _persistIndices(-1, -1)
        switchProfileCommand.command = ["sh", "-c", "easyeffects -r"]
        checkInstalled.running = true
    }

    function _persistIndices(outIdx, inIdx) {
        if (!pluginApi) return
        pluginApi.pluginSettings.currentOutputIndex = outIdx
        pluginApi.pluginSettings.currentInputIndex = inIdx
        pluginApi.saveSettings()
    }

    // ─── Active profile detection ───
    Process {
        id: checkActiveOutput
        command: ["easyeffects", "-a", "output"]
        running: false
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            var data = String(checkActiveOutput.stdout.text || "").trim()
            if (data !== "") root.activeOutputProfile = data
            checkActiveInput.running = true
        }
    }

    Process {
        id: checkActiveInput
        command: ["easyeffects", "-a", "input"]
        running: false
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            var data = String(checkActiveInput.stdout.text || "").trim()
            if (data !== "") root.activeInputProfile = data

            var outputIdx = -1
            for (var i = 0; i < root.outputProfiles.length; i++) {
                if (root.outputProfiles[i] === root.activeOutputProfile) { outputIdx = i; break }
            }
            if (root.activeOutputProfile === "") outputIdx = -1

            var inputIdx = -1
            for (var j = 0; j < root.inputProfiles.length; j++) {
                if (root.inputProfiles[j] === root.activeInputProfile) { inputIdx = j; break }
            }
            if (root.activeInputProfile === "") inputIdx = -1

            root.currentOutputIndex = outputIdx
            root.currentInputIndex = inputIdx
            _persistIndices(outputIdx, inputIdx)
        }
    }

    // ─── Profile list loading ───
    // AIDEV-NOTE: easyeffects -p 2>&1 outputs sections "Output presets:" / "Input presets:"
    // followed by numbered entries like "1\tProfile Name". We parse both sections here.
    Process {
        id: loadProfiles
        command: ["sh", "-c", "easyeffects -p 2>&1"]
        running: false
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            var outputProfiles = []
            var inputProfiles = []
            var currentSection = ""
            var lines = String(loadProfiles.stdout.text || "").split("\n")

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i]
                if (line.toLowerCase().indexOf("output presets") !== -1) {
                    currentSection = "output"
                } else if (line.toLowerCase().indexOf("input presets") !== -1) {
                    currentSection = "input"
                } else if (line.trim() !== "") {
                    var profileName = line.replace(/^\d+[\t\s]+/, "").trim()
                    if (profileName !== "") {
                        if (currentSection === "output") outputProfiles.push(profileName)
                        else if (currentSection === "input") inputProfiles.push(profileName)
                    }
                }
            }

            root.outputProfiles = outputProfiles
            root.inputProfiles = inputProfiles
            root.profilesLoaded = true
            syncActiveProfile()
        }
    }

    // ─── Profile switching ───
    Process {
        id: checkInstalled
        command: ["sh", "-c", "command -v easyeffects"]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                checkRunning.running = true
            } else {
                Logger.e("EasyEffects", "Easy Effects is not installed")
                ToastService.showError("Easy Effects", "Easy Effects is not installed. Please install it first.")
            }
        }
    }

    Process {
        id: checkRunning
        command: ["pgrep", "-x", "easyeffects"]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                switchProfileCommand.running = true
            } else {
                Logger.w("EasyEffects", "Easy Effects not running, starting service...")
                startProcess.running = true
            }
        }
    }

    Process {
        id: startProcess
        command: ["easyeffects", "--service-mode"]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                switchTimer.start()
            } else {
                Logger.e("EasyEffects", "Failed to start Easy Effects")
                ToastService.showError("Easy Effects", "Failed to start Easy Effects. Is it installed?")
            }
        }
    }

    Timer {
        id: switchTimer
        interval: 500
        repeat: false
        onTriggered: switchProfileCommand.running = true
    }

    Process {
        id: switchProfileCommand
        command: ["sh", "-c", ""]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Logger.w("EasyEffects", "Failed to load profile, exit code: " + exitCode)
                ToastService.showError("Easy Effects", "Failed to switch profile")
            }
        }
    }

    // ─── IPC ───
    IpcHandler {
        target: "plugin:easyeffects"

        function refresh(): void { root.refreshProfiles() }
        function reset(): void { root.resetAllProfiles() }

        function togglePanel(): void {
            pluginApi?.withCurrentScreen(screen => pluginApi.togglePanel(screen))
        }

        function status(): string {
            return JSON.stringify({
                "outputProfiles": root.outputProfiles,
                "inputProfiles": root.inputProfiles,
                "currentOutputProfile": root.currentOutputProfile,
                "currentInputProfile": root.currentInputProfile
            })
        }
    }
}

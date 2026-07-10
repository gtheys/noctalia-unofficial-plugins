import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import "codexbar.js" as CodexBar

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 380 * Style.uiScaleRatio
    property real contentPreferredHeight: Math.min(520 * Style.uiScaleRatio, panelContent.implicitHeight + Style.marginL * 2)

    anchors.fill: parent

    // AIDEV-NOTE: currentProvider drives the chip selector and overrides the command.
    // Initialized from pluginSettings, persisted on chip click.
    property string currentProvider: "zai"

    readonly property var activeCommand: {
        var cmd = CodexBar.command(root.pluginApi)
        var i = cmd.indexOf("--provider")
        if (i >= 0 && root.currentProvider !== "") {
            var c = cmd.slice()
            c[i + 1] = root.currentProvider
            cmd = c
        }
        // AIDEV-NOTE: opencodego only supports --source auto (api/cli/oauth/web all error).
        // Force it regardless of the user's global codexbarSource setting.
        if (root.currentProvider === "opencodego") {
            var s = cmd.indexOf("--source")
            if (s >= 0) {
                cmd = cmd.slice()
                cmd[s + 1] = "auto"
            }
        }
        return cmd
    }

    function selectProvider(key) {
        if (currentProvider === key)
            return
        currentProvider = key
        if (pluginApi) {
            pluginApi.pluginSettings.provider = key
            pluginApi.saveSettings()
        }
        refresh()
    }

    property bool loading: false
    property string errorText: ""
    property string sourceName: ""
    property string providerName: ""
    property string versionText: ""
    property string updatedAt: ""
    property string accountEmail: ""
    property string loginMethod: ""
    property string providerId: ""
    property int primaryPercent: -1
    property int secondaryPercent: -1
    property int tertiaryPercent: -1
    property int primaryWindowMinutes: 0
    property int secondaryWindowMinutes: 0
    property int tertiaryWindowMinutes: 0
    property string primaryResetAt: ""
    property string secondaryResetAt: ""
    property string tertiaryResetAt: ""
    property string primaryReset: ""
    property string secondaryReset: ""
    property string tertiaryReset: ""
    property int creditsRemaining: 0
    property int creditEventsCount: 0

    // AIDEV-NOTE: per-provider card titles ("Tokens"/"MCP"/"Credits"...) since codexbar's
    // JSON doesn't name metrics — see CARD_TITLES in codexbar.js.
    readonly property var cardTitles: CodexBar.cardTitles(root.providerId)

    Component.onCompleted: {
        if (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.provider)
            currentProvider = pluginApi.pluginSettings.provider
        refresh()
    }
    onPluginApiChanged: {
        if (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.provider)
            currentProvider = pluginApi.pluginSettings.provider
    }
    onVisibleChanged: if (visible) refresh()

    Process {
        id: codexbarProcess
        command: root.activeCommand
        // AIDEV-NOTE: workingDirectory set to home to avoid shell-init getcwd error
        // when Quickshell inherits a deleted/inaccessible CWD from its parent process.
        workingDirectory: Quickshell.shellDir
        running: false
        stdout: StdioCollector { id: codexbarStdout }
        stderr: StdioCollector { id: codexbarStderr }
        onRunningChanged: root.loading = running
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                var err = String(codexbarStderr.text || "").trim()
                root.errorText = err !== "" ? err : "codexbar exited " + exitCode
                return
            }
            root.parseOutput(codexbarStdout.text)
        }
    }

    function refresh() {
        if (codexbarProcess.running)
            return
        errorText = ""
        codexbarProcess.running = true
    }

    function parseOutput(output) {
        var parsed = CodexBar.parseUsage(output)
        if (parsed.error !== "") {
            errorText = parsed.error
            return
        }

        sourceName = parsed.sourceName
        providerName = parsed.providerName
        versionText = parsed.versionText
        updatedAt = parsed.updatedAt
        accountEmail = parsed.accountEmail
        loginMethod = parsed.loginMethod
        providerId = parsed.providerId
        primaryPercent = parsed.primaryPercent
        secondaryPercent = parsed.secondaryPercent
        tertiaryPercent = parsed.tertiaryPercent
        primaryWindowMinutes = parsed.primaryWindowMinutes
        secondaryWindowMinutes = parsed.secondaryWindowMinutes
        tertiaryWindowMinutes = parsed.tertiaryWindowMinutes
        primaryResetAt = parsed.primaryResetAt
        secondaryResetAt = parsed.secondaryResetAt
        tertiaryResetAt = parsed.tertiaryResetAt
        primaryReset = parsed.primaryReset
        secondaryReset = parsed.secondaryReset
        tertiaryReset = parsed.tertiaryReset
        creditsRemaining = parsed.creditsRemaining
        creditEventsCount = parsed.creditEventsCount
        errorText = ""
    }

    function clampPercent(value) {
        return CodexBar.clampPercent(value)
    }

    function ratio(value) {
        return CodexBar.clampPercent(value) / 100
    }

    function percentLabel(value) {
        return CodexBar.percentLabel(value)
    }

    function windowLabel(minutes) {
        return CodexBar.windowLabel(minutes)
    }

    function formatDateTime(isoText) {
        if (isoText === "")
            return ""
        var d = new Date(isoText)
        if (isNaN(d.getTime()))
            return isoText
        return d.toLocaleString(Qt.locale(), Locale.ShortFormat)
    }

    function updatedLabel() {
        var formatted = formatDateTime(updatedAt)
        return formatted !== "" ? formatted : "—"
    }

    function usageColor(value) {
        if (errorText !== "")
            return Color.mError
        if (value < 0 || isNaN(value))
            return Color.mOutline
        if (value >= 85)
            return Color.mError
        if (value >= 60)
            return Color.mSecondary
        return Color.mPrimary
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: panelContent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Style.marginL
            }
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NIcon {
                    icon: root.errorText !== "" ? "alert-circle" : "ai"
                    color: root.errorText !== "" ? Color.mError : Color.mPrimary
                    pointSize: Style.fontSizeXL
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXXS

                    NText {
                        text: pluginApi?.tr("panel.title")
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NText {
                        text: root.accountEmail !== "" ? root.accountEmail : root.sourceName
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    width: 34
                    height: 34
                    radius: Style.radiusM
                    color: refreshMouse.containsMouse ? Color.mPrimary : Color.mSurfaceVariant
                    border.color: refreshMouse.containsMouse ? Color.mPrimary : Style.capsuleBorderColor
                    border.width: Style.capsuleBorderWidth

                    NIcon {
                        anchors.centerIn: parent
                        icon: root.loading ? "loader" : "refresh"
                        color: refreshMouse.containsMouse ? Color.mOnPrimary : Color.mOnSurfaceVariant
                        RotationAnimation on rotation {
                            running: root.loading
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refresh()
                    }
                }
            }

            // Provider selector chips
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                ProviderChip {
                    key: "zai"
                    label: "Zai"
                    icon: "sparkles"
                    percent: root.currentProvider === "zai" ? root.primaryPercent : -1
                    Layout.fillWidth: true
                }

                ProviderChip {
                    key: "opencodego"
                    label: "OpenCode"
                    icon: "terminal-2"
                    percent: root.currentProvider === "opencodego" ? root.primaryPercent : -1
                    Layout.fillWidth: true
                }

                ProviderChip {
                    key: "openrouter"
                    label: "OpenRouter"
                    icon: "route"
                    percent: root.currentProvider === "openrouter" ? root.primaryPercent : -1
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                visible: root.errorText !== ""
                Layout.fillWidth: true
                implicitHeight: errorTextItem.implicitHeight + Style.marginL * 2
                radius: Style.radiusM
                color: Qt.alpha(Color.mError, 0.12)

                NText {
                    id: errorTextItem
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Style.marginL
                    }
                    text: root.errorText
                    wrapMode: Text.WordWrap
                    pointSize: Style.fontSizeS
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mError
                }
            }

            LimitCard {
                Layout.fillWidth: true
                visible: root.cardTitles[0] !== "" && root.primaryPercent >= 0
                title: root.cardTitles[0]
                subtitle: root.windowLabel(root.primaryWindowMinutes)
                percent: root.primaryPercent
                resetShort: root.primaryReset
                resetFull: root.formatDateTime(root.primaryResetAt)
                barColor: root.usageColor(root.primaryPercent)
            }

            LimitCard {
                Layout.fillWidth: true
                visible: root.cardTitles[1] !== "" && root.secondaryPercent >= 0
                title: root.cardTitles[1]
                subtitle: root.windowLabel(root.secondaryWindowMinutes)
                percent: root.secondaryPercent
                resetShort: root.secondaryReset
                resetFull: root.formatDateTime(root.secondaryResetAt)
                barColor: root.usageColor(root.secondaryPercent)
            }

            LimitCard {
                Layout.fillWidth: true
                visible: root.cardTitles[2] !== "" && root.tertiaryPercent >= 0
                title: root.cardTitles[2]
                subtitle: root.windowLabel(root.tertiaryWindowMinutes)
                percent: root.tertiaryPercent
                resetShort: root.tertiaryReset
                resetFull: root.formatDateTime(root.tertiaryResetAt)
                barColor: root.usageColor(root.tertiaryPercent)
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: metaGrid.implicitHeight + Style.marginL * 2
                radius: Style.radiusL
                color: Color.mSurfaceVariant

                GridLayout {
                    id: metaGrid
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Style.marginL
                    }
                    columns: 2
                    rowSpacing: Style.marginS
                    columnSpacing: Style.marginL

                    MetaItem { label: pluginApi?.tr("panel.login"); value: root.loginMethod !== "" ? root.loginMethod : "—" }
                    MetaItem { label: pluginApi?.tr("panel.provider"); value: root.providerId !== "" ? root.providerId : root.providerName }
                    MetaItem { label: pluginApi?.tr("panel.source"); value: root.sourceName !== "" ? root.sourceName : "—" }
                    MetaItem { label: pluginApi?.tr("panel.codexbar"); value: root.versionText !== "" ? "v" + root.versionText : "—" }
                    MetaItem { label: pluginApi?.tr("panel.credits"); value: pluginApi?.tr("panel.credits-remaining", { count: root.creditsRemaining }) }
                    MetaItem { label: pluginApi?.tr("panel.credit-events"); value: String(root.creditEventsCount) }
                }
            }

            NText {
                Layout.fillWidth: true
                text: pluginApi?.tr("panel.updated", { time: root.updatedLabel() })
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    component ProviderChip: Rectangle {
        id: chip
        property string key: ""
        property string label: ""
        property string icon: ""
        property int percent: -1
        property string planLabel: ""  // shown when no quota data (e.g. Copilot Business = unlimited)

        readonly property bool active: root.currentProvider === key
        readonly property bool hasQuota: percent >= 0

        radius: Style.radiusM
        color: active ? Color.mPrimary : Color.mSurfaceVariant
        implicitHeight: chipCol.implicitHeight + Style.marginM * 2 + 6
        clip: true

        Behavior on color { ColorAnimation { duration: Style.animationFast } }

        ColumnLayout {
            id: chipCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Style.marginM
            }
            spacing: Style.marginXXS

            NIcon {
                icon: chip.icon
                pointSize: Style.fontSizeL
                color: chip.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter

                Behavior on color { ColorAnimation { duration: Style.animationFast } }
            }

            NText {
                text: chip.label
                pointSize: Style.fontSizeS
                font.weight: chip.active ? Style.fontWeightBold : Style.fontWeightNormal
                color: chip.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter

                Behavior on color { ColorAnimation { duration: Style.animationFast } }
            }

            NText {
                visible: !chip.hasQuota && chip.planLabel !== ""
                text: chip.planLabel
                pointSize: Style.fontSizeXXS
                color: chip.active ? Qt.alpha(Color.mOnPrimary, 0.75) : Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter

                Behavior on color { ColorAnimation { duration: Style.animationFast } }
            }
        }

        // Usage bar at bottom
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 4
            radius: 0
            color: chip.active ? Qt.alpha(Color.mOnPrimary, 0.2) : Qt.alpha(Color.mOutline, 0.15)
            visible: chip.hasQuota || chip.planLabel === ""

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: chip.hasQuota ? parent.width * Math.min(1, chip.percent / 100) : 0
                radius: 0
                color: chip.active ? Color.mOnPrimary : Color.mPrimary

                Behavior on width { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectProvider(chip.key)
        }
    }

    component LimitCard: Rectangle {
        id: card
        property string title: ""
        property string subtitle: ""
        property int percent: -1
        property string resetShort: ""
        property string resetFull: ""
        property color barColor: Color.mPrimary

        radius: Style.radiusL
        color: Color.mSurfaceVariant
        implicitHeight: limitLayout.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: limitLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Style.marginL
            }
            spacing: Style.marginS

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXXS

                    NText {
                        text: card.title
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NText {
                        text: card.subtitle
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                    }
                }

                NText {
                    text: root.percentLabel(card.percent)
                    pointSize: Style.fontSizeXXL
                    font.weight: Style.fontWeightBold
                    color: card.barColor
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 10
                radius: Style.radiusXXS
                color: Qt.alpha(Color.mOutline, 0.22)
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    radius: parent.radius
                    color: card.barColor
                    width: parent.width * root.ratio(card.percent)

                    Behavior on width {
                        NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NText {
                    text: pluginApi?.tr("panel.resets")
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                Item { Layout.fillWidth: true }

                NText {
                    text: card.resetShort !== "" ? card.resetShort : (card.resetFull !== "" ? card.resetFull : "—")
                    pointSize: Style.fontSizeXS
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    Layout.maximumWidth: 210 * Style.uiScaleRatio
                }
            }

            NText {
                visible: card.resetFull !== "" && card.resetFull !== card.resetShort
                text: card.resetFull
                pointSize: Style.fontSizeXXS
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }
        }
    }

    component MetaItem: ColumnLayout {
        property string label: ""
        property string value: ""
        spacing: Style.marginXXS
        Layout.fillWidth: true

        NText {
            text: parent.label
            pointSize: Style.fontSizeXXS
            color: Color.mOnSurfaceVariant
            Layout.fillWidth: true
        }

        NText {
            text: parent.value
            pointSize: Style.fontSizeS
            font.weight: Style.fontWeightSemiBold
            color: Color.mOnSurface
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}

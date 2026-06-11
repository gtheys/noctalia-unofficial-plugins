import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen

    readonly property var main: pluginApi?.mainInstance
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: Math.round(280 * Style.uiScaleRatio)
    property real contentPreferredHeight: mainColumn.implicitHeight + Style.marginL * 2

    anchors.fill: parent

    function _closePanel() {
        pluginApi?.withCurrentScreen(s => pluginApi.closePanel(s))
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"
    }

    ColumnLayout {
        id: mainColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Style.marginL
        }
        spacing: Style.marginM

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NText {
                text: "Audio Profiles"
                pointSize: Style.fontSizeL
                font.weight: Font.Normal
                color: Color.mOnSurface
                Layout.fillWidth: true
            }

            NIconButton {
                icon: "x-circle"
                tooltipText: "Reset profiles"
                onClicked: {
                    root.main?.resetAllProfiles()
                    root._closePanel()
                }
            }

            NIconButton {
                icon: "refresh-cw"
                tooltipText: "Refresh profiles"
                onClicked: root.main?.refreshProfiles()
            }
        }

        // ─── Output Presets ───
        NText {
            text: "Output"
            pointSize: Style.fontSizeM
            font.weight: Font.Medium
            color: Color.mOnSurfaceVariant
            visible: (root.main?.outputProfiles?.length ?? 0) > 0
        }

        Repeater {
            model: root.main?.outputProfiles?.length ?? 0

            Rectangle {
                Layout.fillWidth: true
                implicitWidth: root.contentPreferredWidth - Style.marginL * 2
                height: Math.round(40 * Style.uiScaleRatio)
                radius: Style.radiusM
                color: {
                    if (root.main?.currentOutputIndex === index) return Color.mPrimaryContainer
                    if (outputMouse.containsMouse) return Color.mSurfaceContainerHighest
                    return Color.mSurfaceVariant
                }
                Behavior on color { ColorAnimation { duration: Style.animationFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    NIcon {
                        icon: root.main?.currentOutputIndex === index ? "check-circle" : "circle"
                        color: root.main?.currentOutputIndex === index ? Color.mPrimary : Color.mOnSurface
                        pointSize: Style.fontSizeM
                    }

                    NText {
                        text: root.main?.outputProfiles[index] || "Unknown"
                        color: Color.mOnSurface
                        font.weight: root.main?.currentOutputIndex === index ? Font.Medium : Font.Normal
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: outputMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.main?.loadOutputProfile(index)
                        root._closePanel()
                    }
                }
            }
        }

        // ─── Input Presets ───
        Item {
            height: Style.marginS
            visible: (root.main?.inputProfiles?.length ?? 0) > 0
        }

        NText {
            text: "Input"
            pointSize: Style.fontSizeM
            font.weight: Font.Medium
            color: Color.mOnSurfaceVariant
            visible: (root.main?.inputProfiles?.length ?? 0) > 0
        }

        Repeater {
            model: root.main?.inputProfiles?.length ?? 0

            Rectangle {
                Layout.fillWidth: true
                implicitWidth: root.contentPreferredWidth - Style.marginL * 2
                height: Math.round(40 * Style.uiScaleRatio)
                radius: Style.radiusM
                color: {
                    if (root.main?.currentInputIndex === index) return Color.mPrimaryContainer
                    if (inputMouse.containsMouse) return Color.mSurfaceContainerHighest
                    return Color.mSurfaceVariant
                }
                Behavior on color { ColorAnimation { duration: Style.animationFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    NIcon {
                        icon: root.main?.currentInputIndex === index ? "check-circle" : "circle"
                        color: root.main?.currentInputIndex === index ? Color.mPrimary : Color.mOnSurface
                        pointSize: Style.fontSizeM
                    }

                    NText {
                        text: root.main?.inputProfiles[index] || "Unknown"
                        color: Color.mOnSurface
                        font.weight: root.main?.currentInputIndex === index ? Font.Medium : Font.Normal
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: inputMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.main?.loadInputProfile(index)
                        root._closePanel()
                    }
                }
            }
        }

        // ─── Divider ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.mOutline
            opacity: 0.2
        }

        // ─── Open Easy Effects ───
        NButton {
            Layout.fillWidth: true
            text: "Open Easy Effects"
            icon: "external-link"
            onClicked: {
                Quickshell.execDetached(["easyeffects"])
                root._closePanel()
            }
        }
    }

    // Sync active profile when panel opens
    onVisibleChanged: {
        if (visible) root.main?.syncActiveProfile()
    }
}

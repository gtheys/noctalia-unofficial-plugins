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
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var main: pluginApi?.mainInstance
    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"

    property real margins: Style.marginM * 2
    readonly property real contentWidth: isVertical ? Style.capsuleHeight : Math.round(layout.implicitWidth + margins)
    readonly property real contentHeight: isVertical ? Math.round(layout.implicitHeight + margins) : Style.capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusM
        // AIDEV-NOTE: hover highlights capsule (Color.mHover) and flips text/icon to black for contrast
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Item {
            id: layout
            anchors.centerIn: parent
            implicitWidth: iconRow.implicitWidth
            implicitHeight: iconRow.implicitHeight

            RowLayout {
                id: iconRow
                spacing: Style.marginXS

                NIcon {
                    icon: "audio-waveform"
                    color: mouseArea.containsMouse ? "black" : Color.mOnSurface
                }

                NText {
                    visible: !root.isVertical
                    text: {
                        var out = root.main?.currentOutputProfile || "None"
                        var inp = root.main?.currentInputProfile || "None"
                        return (inp !== "None") ? out + " / " + inp : out
                    }
                    pointSize: Style.fontSizeXS
                    color: mouseArea.containsMouse ? "black" : Color.mOnSurface
                }
            }
        }
    }

    NPopupContextMenu {
        id: contextMenu
        model: [
            {
                "label": "Refresh Profiles",
                "action": "refresh",
                "icon": "refresh-cw"
            },
            {
                "label": "Reset Profiles",
                "action": "reset",
                "icon": "x-circle"
            },
            {
                "label": "Plugin Settings",
                "action": "settings",
                "icon": "settings"
            }
        ]
        onTriggered: action => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)
            if (action === "refresh") root.main?.refreshProfiles()
            else if (action === "reset") root.main?.resetAllProfiles()
            else if (action === "settings") BarService.openPluginSettings(screen, pluginApi.manifest)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: TooltipService.show(
            root,
            "Easy Effects: " + (root.main?.currentOutputProfile || "None"),
            BarService.getTooltipDirection(root.screen?.name)
        )
        onExited: TooltipService.hide()

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                pluginApi?.openPanel(root.screen, root)
            } else if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen)
            }
        }
    }
}

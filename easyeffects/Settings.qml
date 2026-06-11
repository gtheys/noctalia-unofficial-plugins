import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    spacing: Style.marginL

    NText {
        text: "Easy Effects Profile Switcher"
        pointSize: Style.fontSizeL
        font.weight: Font.Bold
        color: Color.mOnSurface
    }

    NText {
        Layout.fillWidth: true
        text: "Quickly switch between Easy Effects output and input audio profiles. Profiles are automatically detected by querying Easy Effects directly."
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
    }

    function saveSettings() {
        // No configurable settings currently — nothing to save.
    }
}

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginL

    property var pluginApi: null

    property bool editColorizeByProfile:
        pluginApi?.pluginSettings?.colorizeByProfile ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorizeByProfile ??
        true

    property bool editShowProfile:
        pluginApi?.pluginSettings?.showProfile  ??
        pluginApi?.manifest?.metadata?.defaultSettings?.showProfile ??
        true

    property bool editShowBalancedIcon:
        pluginApi?.pluginSettings?.showBalancedIcon  ??
        pluginApi?.manifest?.metadata?.defaultSettings?.showBalancedIcon ??
        false

    function saveSettings() {
        if (!pluginApi) return
        pluginApi.pluginSettings.colorizeByProfile = root.editColorizeByProfile
        pluginApi.pluginSettings.showProfile = root.editShowProfile
        pluginApi.pluginSettings.showBalancedIcon = root.editShowBalancedIcon
        pluginApi.saveSettings()
    }

    //Dynamic coloring based on selected profile
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.dynamic-coloring")
        description: pluginApi?.tr("settings.dynamic-coloring-desc")
        checked: root.editColorizeByProfile
        onToggled: checked => {
            root.editColorizeByProfile = checked
            root.saveSettings()
        }
    }

    //Show profile in widget
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.show-profile")
        description: pluginApi?.tr("settings.show-profile-desc")
        checked: root.editShowProfile
        onToggled: checked => {
            root.editShowProfile = checked
            root.saveSettings()
        }
    }

    //Show balanced icon
    NToggle {
        enabled: root.editShowProfile
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.show-balanced")
        description: pluginApi?.tr("settings.show-balanced-desc")
        checked: root.editShowBalancedIcon
        onToggled: checked => {
            Logger.d("SettingsView", "showBalancedIcon checked: " + checked)
            root.editShowBalancedIcon = checked
            root.saveSettings()
        }
    }

    Item { Layout.fillHeight: true }
}
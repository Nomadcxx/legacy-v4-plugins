import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var summary: mainInstance?.state?.summary || ({})
  readonly property var detectedModel: summary.model || ({})
  readonly property var availableModels: summary.models || []

  property string valueBridgeHost: cfg.bridgeHost ?? defaults.bridgeHost ?? "127.0.0.1"
  property int valueBridgePort: cfg.bridgePort ?? defaults.bridgePort ?? 19777
  property string valueStateFile: cfg.stateFile ?? defaults.stateFile ?? "~/.cache/noctalia-hermes/state.json"
  property string valueHermesHome: cfg.hermesHome ?? defaults.hermesHome ?? "~/.hermes"
  property string valueHermesCommand: cfg.hermesCommand ?? defaults.hermesCommand ?? "hermes"
  property bool valueAutoStartBridge: cfg.autoStartBridge ?? defaults.autoStartBridge ?? true
  property int valueStatusPollIntervalSec: cfg.statusPollIntervalSec ?? defaults.statusPollIntervalSec ?? 30
  property bool valueHideWhenIdle: cfg.hideWhenIdle ?? defaults.hideWhenIdle ?? false
  property string valueLauncherPrefix: cfg.launcherPrefix ?? defaults.launcherPrefix ?? ">hermes"
  property bool valuePanelPinned: cfg.panelPinned ?? defaults.panelPinned ?? false
  property bool valueShowToolActivity: cfg.showToolActivity ?? defaults.showToolActivity ?? false
  property string valueDefaultProvider: (cfg.defaultProvider || detectedModel.provider || defaults.defaultProvider || "")
  property string valueDefaultModel: (cfg.defaultModel || detectedModel.name || defaults.defaultModel || "")
  readonly property string selectedModelKey: modelKey(valueDefaultProvider, valueDefaultModel)

  spacing: Style.marginL

  NText {
    text: pluginApi?.tr("settings.title")
    pointSize: Style.fontSizeXL
    font.weight: Style.fontWeightBold
    color: Color.mOnSurface
    Layout.fillWidth: true
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.bridgeHost")
      text: root.valueBridgeHost
      onTextChanged: root.valueBridgeHost = text
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: pluginApi?.tr("settings.bridgePort")
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightSemiBold
          color: Color.mOnSurface
        }

        NSpinBox {
          from: 1024
          to: 65535
          value: root.valueBridgePort
          stepSize: 1
          onValueChanged: root.valueBridgePort = value
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: pluginApi?.tr("settings.statusPollIntervalSec")
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightSemiBold
          color: Color.mOnSurface
        }

        NSpinBox {
          from: 5
          to: 300
          value: root.valueStatusPollIntervalSec
          stepSize: 5
          onValueChanged: root.valueStatusPollIntervalSec = value
        }
      }
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.stateFile")
      text: root.valueStateFile
      onTextChanged: root.valueStateFile = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hermesHome")
      text: root.valueHermesHome
      onTextChanged: root.valueHermesHome = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hermesCommand")
      text: root.valueHermesCommand
      onTextChanged: root.valueHermesCommand = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.launcherPrefix")
      text: root.valueLauncherPrefix
      onTextChanged: root.valueLauncherPrefix = text
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.providerSelect")
        model: root.providerOptions()
        currentKey: root.valueDefaultProvider
        minimumWidth: 180
        onSelected: function(key) {
          root.valueDefaultProvider = key;
          if (root.valueDefaultModel !== "" && root.findModel(root.valueDefaultProvider, root.valueDefaultModel) === null) {
            var first = root.firstModelForProvider(key);
            if (first) root.valueDefaultModel = first.model;
          }
        }
      }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.modelSelect")
        model: root.modelOptions(root.valueDefaultProvider)
        currentKey: root.selectedModelKey
        minimumWidth: 320
        onSelected: function(key) {
          var item = root.findModelByKey(key);
          if (!item) return;
          root.valueDefaultProvider = item.provider || "";
          root.valueDefaultModel = item.model || "";
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultProvider")
        text: root.valueDefaultProvider
        onTextChanged: root.valueDefaultProvider = text
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultModel")
        text: root.valueDefaultModel
        onTextChanged: root.valueDefaultModel = text
      }
    }

    NButton {
      text: pluginApi?.tr("settings.applyModel")
      icon: "refresh"
      enabled: root.valueDefaultModel.trim() !== ""
      onClicked: {
        root.saveSettings();
        root.mainInstance?.setModel(root.valueDefaultProvider.trim(), root.valueDefaultModel.trim(), false);
      }
    }

    NToggle {
      label: pluginApi?.tr("settings.autoStartBridge")
      description: pluginApi?.tr("settings.autoStartBridgeDescription")
      checked: root.valueAutoStartBridge
      onToggled: root.valueAutoStartBridge = checked
    }

    NToggle {
      label: pluginApi?.tr("settings.hideWhenIdle")
      description: pluginApi?.tr("settings.hideWhenIdleDescription")
      checked: root.valueHideWhenIdle
      onToggled: root.valueHideWhenIdle = checked
    }

    NToggle {
      label: pluginApi?.tr("settings.panelPinned")
      description: pluginApi?.tr("settings.panelPinnedDescription")
      checked: root.valuePanelPinned
      onToggled: root.valuePanelPinned = checked
    }

    NToggle {
      label: pluginApi?.tr("settings.showToolActivity")
      description: pluginApi?.tr("settings.showToolActivityDescription")
      checked: root.valueShowToolActivity
      onToggled: root.valueShowToolActivity = checked
    }
  }

  function saveSettings() {
    if (!pluginApi) return;
    pluginApi.pluginSettings.bridgeHost = root.valueBridgeHost;
    pluginApi.pluginSettings.bridgePort = root.valueBridgePort;
    pluginApi.pluginSettings.stateFile = root.valueStateFile;
    pluginApi.pluginSettings.hermesHome = root.valueHermesHome;
    pluginApi.pluginSettings.hermesCommand = root.valueHermesCommand;
    pluginApi.pluginSettings.autoStartBridge = root.valueAutoStartBridge;
    pluginApi.pluginSettings.statusPollIntervalSec = root.valueStatusPollIntervalSec;
    pluginApi.pluginSettings.hideWhenIdle = root.valueHideWhenIdle;
    pluginApi.pluginSettings.launcherPrefix = root.valueLauncherPrefix;
    pluginApi.pluginSettings.panelPinned = root.valuePanelPinned;
    pluginApi.pluginSettings.showToolActivity = root.valueShowToolActivity;
    pluginApi.pluginSettings.defaultProvider = root.valueDefaultProvider;
    pluginApi.pluginSettings.defaultModel = root.valueDefaultModel;
    pluginApi.saveSettings();
    root.mainInstance?.setPinnedPanelRequested(root.valuePanelPinned);
  }

  function modelKey(provider, model) {
    return (provider || "") + "::" + (model || "");
  }

  function providerOptions() {
    var seen = {};
    var items = [{ "key": "", "name": pluginApi?.tr("settings.providerCurrent") }];
    for (var i = 0; i < root.availableModels.length; i++) {
      var provider = root.availableModels[i].provider || "";
      if (provider === "" || seen[provider]) continue;
      seen[provider] = true;
      items.push({ "key": provider, "name": provider });
    }
    if (root.valueDefaultProvider !== "" && !seen[root.valueDefaultProvider]) {
      items.push({ "key": root.valueDefaultProvider, "name": root.valueDefaultProvider });
    }
    return items;
  }

  function modelOptions(provider) {
    var items = [];
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if (provider !== "" && item.provider !== provider) continue;
      items.push({
        "key": root.modelKey(item.provider || "", item.model || ""),
        "name": item.name || item.model || ""
      });
    }
    if (root.valueDefaultModel !== "" && root.findModel(root.valueDefaultProvider, root.valueDefaultModel) === null) {
      items.unshift({
        "key": root.selectedModelKey,
        "name": root.valueDefaultModel + (root.valueDefaultProvider ? " (" + root.valueDefaultProvider + ")" : "")
      });
    }
    return items;
  }

  function findModel(provider, model) {
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if ((item.provider || "") === (provider || "") && (item.model || "") === (model || "")) return item;
    }
    return null;
  }

  function findModelByKey(key) {
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if (root.modelKey(item.provider || "", item.model || "") === key) return item;
    }
    return null;
  }

  function firstModelForProvider(provider) {
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if (provider === "" || item.provider === provider) return item;
    }
    return null;
  }
}

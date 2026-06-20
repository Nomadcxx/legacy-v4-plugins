import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root
  visible: false

  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string bridgeHost: cfg.bridgeHost ?? defaults.bridgeHost ?? "127.0.0.1"
  readonly property int bridgePort: cfg.bridgePort ?? defaults.bridgePort ?? 19777
  readonly property string stateFile: cfg.stateFile ?? defaults.stateFile ?? "~/.cache/noctalia-hermes/state.json"
  readonly property string hermesHome: cfg.hermesHome ?? defaults.hermesHome ?? "~/.hermes"
  readonly property string hermesCommand: cfg.hermesCommand ?? defaults.hermesCommand ?? "hermes"
  readonly property bool autoStartBridge: cfg.autoStartBridge ?? defaults.autoStartBridge ?? true
  readonly property int statusPollIntervalSec: cfg.statusPollIntervalSec ?? defaults.statusPollIntervalSec ?? 30
  readonly property string expandedStateFile: expandHome(stateFile)
  readonly property string expandedHermesHome: expandHome(hermesHome)
  readonly property string bridgeScript: (pluginApi?.pluginDir || ".") + "/scripts/hermes_bridge.py"
  readonly property string bridgeTokenFile: expandedStateFile.replace(/\/[^/]*$/, "/bridge.token")
  property string bridgeToken: ""

  property var state: ({
    "bridge": { "status": "offline", "error": "" },
    "hermes": { "status": "unknown", "gateway_pid": "", "model": "", "provider": "" },
    "session": { "id": "", "stored_id": "", "title": "", "running": false, "cwd": "" },
    "messages": [],
    "events": [],
    "approval": { "pending": false, "message": "", "tool_name": "", "request": ({}) },
    "usage": { "input": 0, "output": 0, "total": 0, "cost_usd": null },
    "summary": {
      "model": { "name": "", "provider": "" },
      "models": [],
      "mcp": { "enabled": 0, "total": 0, "status": "unknown" },
      "cron": { "active": 0, "total": 0, "next_run": "", "jobs": [] },
      "activity": { "tool_events": 0, "running_tools": 0, "last_tool": "" },
      "gateway": { "status": "unknown", "platforms": ({}) }
    },
    "updated_at": 0
  })

  property bool pinnedPanelRequested: cfg.panelPinned ?? defaults.panelPinned ?? false
  property bool pinnedPanelVisible: cfg.panelPinned ?? defaults.panelPinned ?? false
  property var pinnedPanelScreen: null

  function expandHome(path) {
    if (!path) return path;
    if (path === "~") return Quickshell.env("HOME") || path;
    if (path.indexOf("~/") === 0) return (Quickshell.env("HOME") || "") + path.slice(1);
    return path;
  }

  function bridgeUrl(path) {
    return "http://" + bridgeHost + ":" + bridgePort + path;
  }

  function refreshState() {
    getJson("/state", function(data) {
      if (data) {
        root.state = data;
      }
    });
  }

  function startBridge() {
    if (bridgeProcess.running) return;
    bridgeProcess.command = [
      "python3",
      bridgeScript,
      "--host", bridgeHost,
      "--port", String(bridgePort),
      "--state-file", expandedStateFile,
      "--hermes-home", expandedHermesHome,
      "--hermes-command", hermesCommand
    ];
    bridgeProcess.running = true;
  }

  function ensureBridge() {
    getJson("/health", function(data) {
      if (data && data.bridge && data.bridge.status === "online") {
        refreshState();
      } else {
        startBridge();
      }
    });
  }

  function autoConfigure() {
    var isFirstRun = !pluginApi?.pluginSettings || Object.keys(pluginApi.pluginSettings).length === 0;
    if (!isFirstRun) return;
    getJson("/detect", function(data) {
      if (!data) return;
      var s = pluginApi?.pluginSettings || ({});
      if (data.hermesHome && data.hermesHomeExists) s.hermesHome = data.hermesHome;
      if (data.hermesCommand) s.hermesCommand = data.hermesCommand;
      if (data.model && data.model.name) s.defaultModel = data.model.name;
      if (data.model && data.model.provider) s.defaultProvider = data.model.provider;
      if (pluginApi) {
        pluginApi.pluginSettings = s;
        pluginApi.saveSettings();
      }
      if (data.hermesHome && data.hermesHome !== root.expandedHermesHome) {
        root.startBridge();
      }
    });
  }

  function createSession() {
    postJson("/session/create", {}, function(data) {
      if (data) root.state = data;
    });
  }

  function resumeSession(sessionId) {
    postJson("/session/resume", { "session_id": sessionId }, function(data) {
      if (data) root.state = data.state || data;
    });
  }

  function sendPrompt(text) {
    postJson("/prompt", { "text": text }, function(data) {
      if (data && data.state) root.state = data.state;
    });
  }

  function interrupt() {
    postJson("/interrupt", {}, function(data) {
      if (data && data.state) root.state = data.state;
    });
  }

  function respondApproval(choice, all) {
    postJson("/approval", { "choice": choice, "all": all || false }, function(data) {
      if (data && data.state) root.state = data.state;
    });
  }

  function setModel(provider, model, persist) {
    postJson("/model", { "provider": provider || "", "model": model || "", "persist": persist || false }, function(data) {
      if (data && data.state) root.state = data.state;
    });
  }

  function openPreferredPanel(screen, buttonItem) {
    if (root.cfg.panelPinned ?? root.defaults.panelPinned ?? false) {
      root.openPinnedPanel(screen);
      return;
    }
    if (screen) {
      root.pluginApi?.openPanel(screen, buttonItem || null);
      return;
    }
    root.pluginApi?.withCurrentScreen(function(currentScreen) {
      if (currentScreen) root.pluginApi.openPanel(currentScreen, buttonItem || null);
    });
  }

  function openPinnedPanel(screen) {
    if (screen) {
      root.pinnedPanelScreen = screen;
      root.pinnedPanelVisible = true;
      root.refreshState();
      return;
    }
    root.pluginApi?.withCurrentScreen(function(currentScreen) {
      if (currentScreen) {
        root.pinnedPanelScreen = currentScreen;
        root.pinnedPanelVisible = true;
        root.refreshState();
      }
    });
  }

  function closePinnedPanel() {
    root.pinnedPanelVisible = false;
  }

  function setPinnedPanelRequested(value) {
    pinnedPanelRequested = value;
    if (value) {
      root.openPinnedPanel(root.pluginApi?.panelOpenScreen);
      if (root.pluginApi?.panelOpenScreen) root.pluginApi.closePanel(root.pluginApi.panelOpenScreen);
    } else {
      root.closePinnedPanel();
    }
  }

  function oneShot(text) {
    postJson("/oneshot", { "text": text }, function(data) {
      if (data && data.state) root.state = data.state;
    });
  }

  function getJson(path, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) return;
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          callback(JSON.parse(xhr.responseText));
        } catch (e) {
          setBridgeError("Invalid bridge response");
          callback(null);
        }
      } else {
        setBridgeError("Bridge request failed: " + xhr.status);
        callback(null);
      }
    };
    xhr.open("GET", bridgeUrl(path));
    if (root.bridgeToken) {
      xhr.setRequestHeader("X-Bridge-Token", root.bridgeToken);
    }
    xhr.send();
  }

  function postJson(path, payload, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) return;
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          callback(JSON.parse(xhr.responseText));
        } catch (e) {
          setBridgeError("Invalid bridge response");
          callback(null);
        }
      } else {
        setBridgeError("Bridge request failed: " + xhr.status);
        callback(null);
      }
    };
    xhr.open("POST", bridgeUrl(path));
    if (root.bridgeToken) {
      xhr.setRequestHeader("X-Bridge-Token", root.bridgeToken);
    }
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.send(JSON.stringify(payload || {}));
  }

  function setBridgeError(message) {
    var next = root.state;
    next.bridge = next.bridge || {};
    next.bridge.status = "offline";
    next.bridge.error = message;
    root.state = next;
  }

  function loadStateFromFile() {
    try {
      var text = stateFileView.text();
      if (!text || text.trim() === "") return;
      root.state = JSON.parse(text);
    } catch (e) {
      setBridgeError("Invalid state file");
    }
  }

  Process {
    id: bridgeProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.setBridgeError("Bridge exited: " + exitCode);
      }
    }
  }

  FileView {
    id: stateFileView
    path: root.expandedStateFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadStateFromFile()
    onLoadFailed: root.refreshState()
  }

  FileView {
    id: tokenFileView
    path: root.bridgeTokenFile
    watchChanges: true
    printErrors: false
    onLoaded: {
      var text = tokenFileView.text();
      root.bridgeToken = text ? text.trim() : "";
    }
    onFileChanged: reload()
    onLoadFailed: {}
  }

  Timer {
    interval: root.statusPollIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.ensureBridge()
  }

  Component.onCompleted: {
    if (root.autoStartBridge) {
      root.ensureBridge();
    }
    root.autoConfigure();
    if (root.pinnedPanelRequested && root.pinnedPanelVisible) {
      root.openPinnedPanel(null);
    }
  }

  PinnedPanelWindow {
    pluginApi: root.pluginApi
    panelScreen: root.pinnedPanelScreen
    active: root.pinnedPanelRequested && root.pinnedPanelVisible && (root.cfg.panelPinned ?? root.defaults.panelPinned ?? false)
  }
}

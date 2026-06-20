import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var pluginApi: null
  property var state: ({})

  readonly property var bridge: state.bridge || ({})
  readonly property var hermes: state.hermes || ({})
  readonly property var session: state.session || ({})
  readonly property string bridgeStatus: bridge.status || "offline"
  readonly property string hermesStatus: hermes.status || "unknown"
  readonly property bool bridgeOnline: bridgeStatus === "online"
  readonly property string status: bridgeOnline ? hermesStatus : "offline"
  readonly property string title: session.title || session.id || pluginApi?.tr("panel.noSession")
  readonly property string subtitle: {
    var parts = [];
    if (hermes.provider) parts.push(hermes.provider);
    if (hermes.model) parts.push(hermes.model);
    if (session.cwd) parts.push(session.cwd);
    if (parts.length === 0 && bridge.error) return bridge.error;
    return parts.join(" · ");
  }

  function statusIcon() {
    switch (status) {
      case "offline": return "power";
      case "idle": return "circle-check";
      case "busy": return "loader";
      case "attention": return "bell-ringing";
      case "degraded": return "alert-circle";
      case "error": return "alert-triangle";
      default: return "help-circle";
    }
  }

  function statusColor() {
    switch (status) {
      case "offline": return Color.mError;
      case "attention": return "#f59e0b";
      case "degraded": return "#f97316";
      case "error": return Color.mError;
      default: return Color.mPrimary;
    }
  }

  Layout.fillWidth: true
  radius: Style.radiusS
  color: Color.mSurface
  implicitHeight: headerLayout.implicitHeight + Style.marginL * 2

  RowLayout {
    id: headerLayout
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
      margins: Style.marginL
    }
    spacing: Style.marginM

    Rectangle {
      Layout.preferredWidth: Style.baseWidgetSize
      Layout.preferredHeight: Style.baseWidgetSize
      radius: Style.radiusL
      color: Qt.rgba(root.statusColor().r, root.statusColor().g, root.statusColor().b, 0.14)

      NIcon {
        anchors.centerIn: parent
        icon: root.statusIcon()
        pointSize: Style.fontSizeXL
        color: root.statusColor()
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXXS

      NText {
        text: root.title
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: Color.mOnSurface
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      NText {
        visible: root.subtitle !== ""
        text: root.subtitle
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }

    NText {
      text: root.status
      pointSize: Style.fontSizeS
      font.weight: Style.fontWeightSemiBold
      color: root.statusColor()
      Layout.alignment: Qt.AlignVCenter
    }
  }
}

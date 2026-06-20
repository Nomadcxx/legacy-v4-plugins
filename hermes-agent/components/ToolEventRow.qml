import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var event: ({})

  readonly property string kind: event.kind || event.type || "event"
  readonly property string title: event.title || event.name || kind
  readonly property string detail: event.detail || event.message || event.path || ""

  Layout.fillWidth: true
  radius: Style.radiusS
  color: Color.mSurface
  implicitHeight: eventLayout.implicitHeight + Style.marginM * 2

  RowLayout {
    id: eventLayout
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
      margins: Style.marginM
    }
    spacing: Style.marginM

    NIcon {
      icon: root.kind === "error" ? "alert-circle" : "terminal-2"
      pointSize: Style.fontSizeM
      color: root.kind === "error" ? Color.mError : Color.mOnSurfaceVariant
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXXS

      NText {
        text: root.title
        pointSize: Style.fontSizeS
        font.weight: Style.fontWeightSemiBold
        color: Color.mOnSurface
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      NText {
        visible: root.detail !== ""
        text: root.detail
        pointSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
    }
  }
}

import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "CliampModel.js" as Model

Panel {
  id: root
  moduleName: "miguel.cliamp-nowplaying"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property var w: root.hostWidget
  readonly property real progress: w && w.duration > 0 ? Math.max(0, Math.min(1, w.position / w.duration)) : 0

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        Text {
          width: parent.width
          text: "cliamp is not running"
          color: Qt.darker(root.barForeground, 1.3)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
          visible: !root.w || !root.w.hasPlayer
        }

        Item {
          width: parent.width
          height: sections.implicitHeight
          visible: root.w && root.w.hasPlayer

          Column {
            id: sections
            width: parent.width
            spacing: content.spacing

              // --- track ------------------------------------------------------
  
              Text {
            width: parent.width
            text: root.w.title || "Nothing playing"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
          }
  
          Text {
            width: parent.width
            text: root.w.artist
            color: Qt.darker(root.barForeground, 1.3)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            visible: text !== ""
          }
  
          Text {
            width: parent.width
            text: root.w.album + (root.w.isStream ? (root.w.album ? "  ·  Stream" : "Stream") : "")
            color: Qt.darker(root.barForeground, 1.6)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            visible: text !== ""
          }
  
          // --- progress -------------------------------------------------------
  
          Column {
            width: parent.width
            spacing: Style.space(4)
            visible: root.w.duration > 0
  
            Rectangle {
              width: parent.width
              height: Math.max(3, Math.round(Style.space(4)))
              radius: height / 2
              color: Style.selectedFillFor(root.barForeground, Color.accent)
  
              Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: height / 2
                color: root.barForeground
  
                Behavior on width {
                  enabled: !root.w || !root.w.paused
                  NumberAnimation { duration: 400; easing.type: Easing.Linear }
                }
              }
            }
  
            Row {
              width: parent.width
              spacing: Style.space(6)

              Text {
                id: elapsedText
                text: Model.formatDuration(root.w.position)
                color: Qt.darker(root.barForeground, 1.3)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }

              Rectangle {
                id: dividerRect
                width: Math.max(1, Math.round(Style.space(1)))
                height: Style.space(9)
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.darker(root.barForeground, 1.7)
                radius: width / 2
              }

              Item { width: parent.width - elapsedText.implicitWidth - durationText.implicitWidth - dividerRect.implicitWidth - parent.spacing * 3 }

              Text {
                id: durationText
                text: Model.formatDuration(root.w.duration)
                color: Qt.darker(root.barForeground, 1.3)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }
  
          // --- controls -------------------------------------------------------
  
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(6)
  
            Button {
              iconText: "󰒮"
              foreground: root.barForeground
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY
              enabled: root.w && root.w.hasPlayer
              opacity: enabled ? 1.0 : 0.4
              onClicked: if (root.w) root.w.previous()
            }
  
            Button {
              iconText: root.w && root.w.playing ? "󰏤" : "󰐊"
              foreground: root.barForeground
              horizontalPadding: Style.spacing.panelGap
              verticalPadding: Style.spacing.controlPaddingY
              iconSize: Style.font.iconLarge
              enabled: root.w && root.w.hasPlayer
              opacity: enabled ? 1.0 : 0.4
              onClicked: if (root.w) root.w.playPause()
            }
  
            Button {
              iconText: "󰒭"
              foreground: root.barForeground
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY
              enabled: root.w && root.w.hasPlayer
              opacity: enabled ? 1.0 : 0.4
              onClicked: if (root.w) root.w.next()
            }
          }
  
          // --- volume ---------------------------------------------------------
  
          Row {
            width: parent.width
            spacing: Style.space(8)
  
            Text {
              text: "󰝟"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              anchors.verticalCenter: parent.verticalCenter
            }
  
            PanelSlider {
              id: volumeSlider
              bar: root.bar
              width: parent.width - Style.space(34)
              minimum: -30
              maximum: 6
              step: 1
              integer: true
              value: root.w ? root.w.volumeDb : 0
              enabled: root.w && root.w.hasPlayer
              opacity: enabled ? 1.0 : 0.4
              onReleased: function(v) { if (root.w) root.w.setVolume(Math.round(v)) }
            }
          }
  
          // --- status line ----------------------------------------------------
  
          Row {
            width: parent.width
            spacing: Style.space(10)
            visible: root.w && (root.w.shuffleOn || root.w.repeatMode !== "Off" || root.w.speed !== 1)
  
            Text {
              text: "Shuffle " + (root.w.shuffleOn ? "on" : "off")
              color: Qt.darker(root.barForeground, 1.6)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              visible: root.w && root.w.shuffleOn
            }
  
            Text {
              text: "Repeat " + root.w.repeatMode
              color: Qt.darker(root.barForeground, 1.6)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              visible: root.w && root.w.repeatMode !== "Off"
            }
  
          Text {
            text: root.w.speed.toFixed(2) + "×"
            color: Qt.darker(root.barForeground, 1.6)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            visible: root.w && root.w.speed !== 1
          }
        }

            // --- up next ------------------------------------------------------

            PanelSeparator {
              visible: root.w && root.w.hasNext
              foreground: root.barForeground
            }

            Row {
              width: parent.width
              spacing: Style.space(8)
              visible: root.w && root.w.hasNext

              Text {
                id: upNextLabel
                text: "Up next:"
                color: Qt.darker(root.barForeground, 1.6)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                width: parent.width - parent.spacing - upNextLabel.implicitWidth
                text: root.w.nextTitle + (root.w.nextArtist ? " — " + root.w.nextArtist : "")
                color: Qt.darker(root.barForeground, 1.2)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }
          }
        }
      }
    }
  }
}

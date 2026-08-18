import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "CliampModel.js" as Model

BarWidget {
  id: root
  moduleName: "miguel.cliamp-nowplaying"

  // --- playback state (mirrors `cliamp status --json`) ---------------------

  property bool cliampAvailable: false
  property string state: "stopped"
  property string title: ""
  property string artist: ""
  property string album: ""
  property bool isStream: false
  property real position: 0
  property real duration: 0
  property int volumeDb: 0
  property bool shuffleOn: false
  property string repeatMode: "Off"
  property real speed: 1

  readonly property bool playing: state === "playing"
  readonly property bool paused: state === "paused"
  readonly property bool hasPlayer: cliampAvailable
  readonly property string glyph: playing ? "󰏤" : "󰐊"
  readonly property string label: title + (artist ? "  ·  " + artist : "")

  // --- settings -------------------------------------------------------------

  readonly property bool hideWhenStopped: {
    var v = setting("hideWhenStopped", true)
    if (typeof v === "string") return v === "true" || v === "1" || v === "on"
    return v !== false
  }
  readonly property real maxLabelWidth: {
    var v = Number(setting("maxWidth", 90))
    return isFinite(v) && v > 0 ? v : 90
  }

  // --- panel lifecycle -----------------------------------------------------

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  implicitWidth: visible ? row.implicitWidth + Style.space(14) : 0
  implicitHeight: barSize
  visible: hasPlayer || !hideWhenStopped

  // --- polling -------------------------------------------------------------

  Timer {
    id: pollTimer
    interval: 2000
    repeat: true
    triggeredOnStart: true
    running: true
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  Process {
    id: statusProc
    command: ["cliamp", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var data = Model.parseStatus(String(text || "").trim())
        if (!data) {
          root.cliampAvailable = false
          root.state = "stopped"
          root.title = ""
          root.artist = ""
          root.album = ""
          root.isStream = false
          root.position = 0
          root.duration = 0
          root.volumeDb = 0
          root.shuffleOn = false
          root.repeatMode = "Off"
          root.speed = 1
          pollTimer.interval = 5000
          return
        }
        root.cliampAvailable = true
        root.state = String(data.state || "stopped")
        root.title = Model.trackTitle(data)
        root.artist = Model.trackArtist(data)
        root.album = Model.trackAlbum(data)
        root.isStream = Model.isStream(data)
        root.position = Model.positionSecs(data)
        root.duration = Model.durationSecs(data)
        root.volumeDb = Model.volumeDb(data)
        root.shuffleOn = Model.shuffleOn(data)
        root.repeatMode = Model.repeatMode(data)
        root.speed = Model.speedOf(data)
        pollTimer.interval = 2000
      }
    }
  }

  // --- controls ------------------------------------------------------------

  Process {
    id: actionProc
    command: ["cliamp", "toggle"]
  }

  function runAction(args) {
    if (!root.hasPlayer || actionProc.running) return
    actionProc.command = ["cliamp"].concat(args)
    actionProc.running = true
  }

  function playPause() {
    root.runAction(["toggle"])
  }

  function next() {
    root.runAction(["next"])
  }

  function previous() {
    root.runAction(["prev"])
  }

  function setVolume(db) {
    root.volumeDb = db
    root.runAction(["volume", String(db)])
  }

  // --- bar content ---------------------------------------------------------

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      id: glyph
      anchors.verticalCenter: parent.verticalCenter
      text: root.glyph
      color: root.playing ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.5)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
      Behavior on color {
        enabled: !root.bar || root.bar.foregroundAnimationEnabled
        ColorAnimation { duration: 160 }
      }
    }

    Item {
      id: scrollClip
      width: Math.max(8, root.maxLabelWidth)
      height: glyph.height
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.bar.vertical && root.title !== ""

      Text {
        id: labelText
        text: root.label
        color: root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter

        NumberAnimation on x {
          id: scrollAnim
          running: !root.opened && !root.bar.vertical
          loops: Animation.Infinite
          duration: Math.max(6000, labelText.implicitWidth * 25)
          from: scrollClip.width
          to: -labelText.implicitWidth
          easing.type: Easing.Linear
        }
      }
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    keepSpace: true
    tooltipText: root.tooltipText
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.playPause()
      else if (buttonCode === Qt.RightButton) root.toggle()
      else if (buttonCode === Qt.MiddleButton) root.next()
    }
    onWheelMoved: function(delta) {
      if (delta > 0) root.previous()
      else if (delta < 0) root.next()
    }
  }

  readonly property string tooltipText: hasPlayer
    ? root.title + (root.artist ? " — " + root.artist : "") + (root.album ? " (" + root.album + ")" : "")
    : "cliamp is not running"

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  onBarChanged: injectPanel()

  // --- IPC for hotkeys / scripts --------------------------------------------

  function statusJson() {
    return JSON.stringify({
      available: root.cliampAvailable,
      state: root.state,
      title: root.title,
      artist: root.artist,
      album: root.album,
      stream: root.isStream,
      position: root.position,
      duration: root.duration,
      volume: root.volumeDb,
      shuffle: root.shuffleOn,
      repeat: root.repeatMode,
      speed: root.speed,
      widgetWidth: root.width,
      slotWidth: scrollClip.width,
      labelWidth: labelText.implicitWidth,
      animRunning: scrollAnim.running
    })
  }

  IpcHandler {
    target: "cliamp"

    function status(): string {
      return root.statusJson()
    }

    function playPause(): string {
      if (!root.hasPlayer) return "unhandled"
      root.playPause()
      return "ok"
    }

    function play(): string {
      if (!root.hasPlayer) return "unhandled"
      if (!root.playing) root.runAction(["play"])
      return "ok"
    }

    function pause(): string {
      if (!root.hasPlayer) return "unhandled"
      if (root.playing) root.runAction(["pause"])
      return "ok"
    }

    function next(): string {
      if (!root.hasPlayer) return "unhandled"
      root.next()
      return "ok"
    }

    function previous(): string {
      if (!root.hasPlayer) return "unhandled"
      root.previous()
      return "ok"
    }

    function volume(db: string): string {
      if (!root.hasPlayer) return "unhandled"
      var value = parseFloat(String(db || ""))
      if (!isFinite(value)) return "unhandled"
      root.setVolume(Math.max(-30, Math.min(6, Math.round(value))))
      return "ok"
    }

    function panel(): string {
      root.toggle()
      return "ok"
    }
  }
}

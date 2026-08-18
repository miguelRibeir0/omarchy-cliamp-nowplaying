function parseStatus(raw) {
  if (!raw) return null
  try {
    var data = JSON.parse(raw)
    if (!data || data.ok !== true) return null
    return data
  } catch (e) {
    return null
  }
}

function trackOf(data) {
  return data && data.track ? data.track : {}
}

function trackTitle(data) {
  return String(trackOf(data).title || "")
}

function trackArtist(data) {
  return String(trackOf(data).artist || "")
}

function trackAlbum(data) {
  return String(trackOf(data).album || "")
}

function isStream(data) {
  return trackOf(data).stream === true
}

function durationSecs(data) {
  var value = trackOf(data).duration_secs
  return typeof value === "number" && isFinite(value) && value > 0 ? value : 0
}

function positionSecs(data) {
  var value = data && data.position
  return typeof value === "number" && isFinite(value) ? Math.max(0, value) : 0
}

function volumeDb(data) {
  var value = data && data.volume
  return typeof value === "number" && isFinite(value) ? Math.round(value) : 0
}

function shuffleOn(data) {
  return !!(data && data.shuffle)
}

function repeatMode(data) {
  var value = data && data.repeat
  if (value === undefined || value === null) return "Off"
  return String(value)
}

function speedOf(data) {
  var value = data && data.speed
  return typeof value === "number" && isFinite(value) ? value : 1
}

function isPlaying(data) {
  return !!(data && data.state === "playing")
}

function isPaused(data) {
  return !!(data && data.state === "paused")
}

function hasTrack(data) {
  return !!trackOf(data) && trackTitle(data) !== ""
}

function parseNext(raw) {
  if (!raw) return null
  try {
    var start = String(raw).indexOf("{")
    if (start < 0) return null
    var data = JSON.parse(String(raw).slice(start))
    if (!data || data.shuffle === true) return null
    var t = data.track
    if (!t) return null
    return {
      title: String(t.title || ""),
      artist: String(t.artist || ""),
      album: String(t.album || "")
    }
  } catch (e) {
    return null
  }
}

function formatDuration(secs) {
  var total = Math.max(0, Math.round(secs || 0))
  var minutes = Math.floor(total / 60)
  var seconds = total % 60
  return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
}

if (typeof module !== "undefined") {
  module.exports = {
    parseStatus: parseStatus,
    trackOf: trackOf,
    trackTitle: trackTitle,
    trackArtist: trackArtist,
    trackAlbum: trackAlbum,
    isStream: isStream,
    durationSecs: durationSecs,
    positionSecs: positionSecs,
    volumeDb: volumeDb,
    shuffleOn: shuffleOn,
    repeatMode: repeatMode,
    speedOf: speedOf,
    isPlaying: isPlaying,
    isPaused: isPaused,
    hasTrack: hasTrack,
    parseNext: parseNext,
    formatDuration: formatDuration
  }
}

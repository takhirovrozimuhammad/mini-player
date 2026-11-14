import Foundation
import AppKit

/// Only public Apple Events / AppleScript. No private MediaRemote APIs.
/// These queries can trigger the macOS Automation permission prompt.
final class PlayerBridge {

    static func currentTrack() -> TrackSnapshot? {
        // Try active playback first; if both are paused, show most recently queried.
        let spotify = readSpotify()
        let music = readMusic()
        if spotify?.playing == true { return spotify }
        if music?.playing == true { return music }
        return spotify ?? music
    }

    private static func run(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let descriptor = script.executeAndReturnError(&error)
        guard error == nil else { return nil }
        return descriptor.stringValue
    }

    private static func readSpotify() -> TrackSnapshot? {
        let source = """
        if application "Spotify" is not running then return ""
        tell application "Spotify"
            try
                set t to current track
                set s to (player state as text)
                set art to ""
                try
                    set art to artwork url of t as text
                end try
                return (name of t as text) & (ASCII character 31) & (artist of t as text) & (ASCII character 31) & (album of t as text) & (ASCII character 31) & (duration of t as text) & (ASCII character 31) & (player position as text) & (ASCII character 31) & s & (ASCII character 31) & art
            on error
                return ""
            end try
        end tell
        """
        return parse(run(source), source: .spotify, durationDivisor: 1000)
    }

    private static func readMusic() -> TrackSnapshot? {
        let source = """
        if application "Music" is not running then return ""
        tell application "Music"
            try
                set t to current track
                return (name of t as text) & (ASCII character 31) & (artist of t as text) & (ASCII character 31) & (album of t as text) & (ASCII character 31) & (duration of t as text) & (ASCII character 31) & (player position as text) & (ASCII character 31) & (player state as text) & (ASCII character 31) & ""
            on error
                return ""
            end try
        end tell
        """
        return parse(run(source), source: .music, durationDivisor: 1)
    }

    private static func parse(_ result: String?, source: TrackSnapshot.Source, durationDivisor: Double) -> TrackSnapshot? {
        guard let result, !result.isEmpty else { return nil }
        let parts = result.components(separatedBy: String(UnicodeScalar(31)!))
        guard parts.count >= 6, !parts[0].isEmpty else { return nil }
        let duration = (Double(parts[3]) ?? 0) / durationDivisor
        let position = Double(parts[4]) ?? 0
        return TrackSnapshot(source: source,
                             title: parts[0], artist: parts[1], album: parts[2],
                             duration: duration, position: position,
                             playing: parts[5].lowercased().contains("playing"),
                             artworkURL: parts.count > 6 ? URL(string: parts[6]) : nil)
    }

    static func command(_ action: MediaAction, for source: TrackSnapshot.Source) {
        guard source != .demo else { return }
        let application = source == .spotify ? "Spotify" : "Music"
        let command: String
        switch action {
        case .playPause: command = "playpause"
        case .next: command = "next track"
        case .previous: command = "previous track"
        case .seek(let seconds):
            command = "set player position to \(max(0, Int(seconds)))"
        }
        _ = run("tell application \"\(application)\" to \(command)")
    }
}

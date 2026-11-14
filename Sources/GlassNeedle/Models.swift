import Foundation
import AppKit

struct TrackSnapshot: Equatable, Sendable {
    enum Source: String, Sendable { case spotify = "Spotify", music = "Apple Music", demo = "Preview" }
    var source: Source
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var position: TimeInterval
    var playing: Bool
    var artworkURL: URL?
    var identifier: String { "\(source.rawValue)|\(title)|\(artist)|\(album)" }
}

struct LyricLine: Identifiable, Equatable {
    let time: TimeInterval
    let text: String
    var id: String { "\(time)-\(text)" }
}

enum MediaAction {
    case playPause, next, previous
    case seek(TimeInterval)
}

enum StageStyle: String, CaseIterable, Identifiable {
    case cinematic = "Cinematic lyrics"
    case constellation = "Constellation words"
    case minimal = "Minimal clock"
    var id: String { rawValue }
}

enum DesktopStyle: String, CaseIterable, Identifiable {
    case vinyl = "Vinyl"
    case artwork = "Artwork"
    case lyrics = "Lyrics"
    var id: String { rawValue }
}

enum AccentStyle: String, CaseIterable, Identifiable {
    case aurora = "Aurora"
    case amethyst = "Amethyst"
    case ember = "Ember"
    case graphite = "Graphite"
    case album = "Album adaptive"
    var id: String { rawValue }
    var color: NSColor {
        switch self {
        case .aurora: return NSColor(calibratedRed: 0.32, green: 0.86, blue: 0.79, alpha: 1)
        case .amethyst: return NSColor(calibratedRed: 0.61, green: 0.42, blue: 1, alpha: 1)
        case .ember: return NSColor(calibratedRed: 1, green: 0.46, blue: 0.29, alpha: 1)
        case .graphite: return NSColor(calibratedRed: 0.76, green: 0.81, blue: 0.91, alpha: 1)
        case .album: return NSColor(calibratedRed: 0.65, green: 0.48, blue: 0.96, alpha: 1)
        }
    }
}

import Foundation
import Combine
import AppKit

@MainActor
final class MediaStore: ObservableObject {
    @Published private(set) var track: TrackSnapshot?
    @Published private(set) var artwork: NSImage?
    @Published private(set) var lyrics: [LyricLine] = []
    @Published private(set) var artworkColor: NSColor = NSColor(calibratedRed: 0.6, green: 0.43, blue: 0.92, alpha: 1)
    @Published private(set) var lastSync = Date()
    @Published private(set) var isFetching = false

    private var timer: Timer?
    private var busy = false
    private var lastArtworkID = ""
    private var lastLyricsID = ""
    private let settings: GlassSettings
    private var cachedLyrics: [String: [LyricLine]] = [:]

    init(settings: GlassSettings) { self.settings = settings }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        timer?.tolerance = 0.25
    }

    func stop() { timer?.invalidate(); timer = nil }

    func refresh() {
        if settings.demoMode {
            if track?.source != .demo {
                apply(TrackSnapshot(source: .demo, title: "A Different Horizon",
                    artist: "GlassNeedle Preview", album: "Atmospheres",
                    duration: 244, position: 18, playing: true, artworkURL: nil))
            }
            return
        }
        if track?.source == .demo { track = nil; lyrics = []; artwork = nil }
        guard !busy else { return }
        busy = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = PlayerBridge.currentTrack()
            DispatchQueue.main.async { [weak self] in
                self?.busy = false
                self?.apply(result)
            }
        }
    }

    private func apply(_ next: TrackSnapshot?) {
        guard let next else {
            if track != nil { track = nil; artwork = nil; lyrics = []; lastArtworkID = ""; lastLyricsID = "" }
            return
        }
        let oldID = track?.identifier
        track = next
        lastSync = Date()
        if next.identifier != oldID {
            artwork = nil
            lyrics = []
            refreshArtwork(for: next)
            refreshLyrics(for: next)
        }
        if next.source == .demo {
            lyrics = [
                LyricLine(time: 0, text: "A quiet night, a distant light"),
                LyricLine(time: 14, text: "The world moves slowly out of sight"),
                LyricLine(time: 30, text: "Another horizon waits for me"),
                LyricLine(time: 45, text: "And everything is what it could be")
            ]
        }
    }

    var progress: TimeInterval {
        guard let track else { return 0 }
        let elapsed = track.playing ? Date().timeIntervalSince(lastSync) : 0
        return min(track.duration, max(0, track.position + elapsed))
    }

    func lyricIndex(at time: TimeInterval) -> Int {
        guard !lyrics.isEmpty else { return -1 }
        return lyrics.lastIndex(where: { $0.time <= time }) ?? -1
    }

    func perform(_ action: MediaAction) {
        guard var current = track else { return }
        if current.source == .demo {
            switch action {
            case .playPause: current.playing.toggle()
            case .seek(let value): current.position = min(current.duration, max(0, value))
            case .next: current.position = 0
            case .previous: current.position = 0
            }
            current.position = progress
            if case .seek(let value) = action { current.position = value }
            track = current
            lastSync = Date()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            PlayerBridge.command(action, for: current.source)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.refresh() }
        }
    }

    private func refreshLyrics(for next: TrackSnapshot) {
        guard next.source != .demo else { return }
        let id = next.identifier
        guard id != lastLyricsID else { return }
        lastLyricsID = id
        if let cached = cachedLyrics[id] { lyrics = cached; return }
        isFetching = true
        LyricsService.fetch(for: next) { [weak self] lines in
            DispatchQueue.main.async {
                guard let self else { return }
                self.cachedLyrics[id] = lines
                if self.track?.identifier == id { self.lyrics = lines; self.isFetching = false }
            }
        }
    }

    private func refreshArtwork(for next: TrackSnapshot) {
        let id = next.identifier
        guard id != lastArtworkID else { return }
        lastArtworkID = id
        if let url = next.artworkURL, url.scheme?.lowercased() == "https" {
            loadImage(from: url, id: id)
        } else {
            // Public iTunes artwork lookup; no credentials. Track names leave the device for this lookup.
            var query = URLComponents(string: "https://itunes.apple.com/search")!
            query.queryItems = [
                URLQueryItem(name: "term", value: "\(next.artist) \(next.title)"),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "song"),
                URLQueryItem(name: "limit", value: "1")
            ]
            guard let url = query.url else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let item = (json["results"] as? [[String: Any]])?.first,
                      let small = item["artworkUrl100"] as? String,
                      let artURL = URL(string: small.replacingOccurrences(of: "100x100", with: "600x600")) else { return }
                Task { @MainActor [weak self] in self?.loadImage(from: artURL, id: id) }
            }.resume()
        }
    }

    private func loadImage(from url: URL, id: String) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            let sampled = Self.sampleColor(from: image)
            DispatchQueue.main.async {
                guard let self, self.track?.identifier == id else { return }
                self.artwork = image
                self.artworkColor = sampled
            }
        }.resume()
    }

    private nonisolated static func sampleColor(from image: NSImage) -> NSColor {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff), bitmap.pixelsWide > 0, bitmap.pixelsHigh > 0 else { return .systemPurple }
        let coords: [(Double, Double)] = [(0.24,0.23),(0.50,0.28),(0.76,0.23),(0.27,0.65),(0.54,0.7),(0.78,0.72)]
        var red = 0.0, green = 0.0, blue = 0.0, used = 0.0
        for (x,y) in coords {
            let cx = Int(Double(bitmap.pixelsWide - 1) * x)
            let cy = Int(Double(bitmap.pixelsHigh - 1) * y)
            guard let c = bitmap.colorAt(x: cx, y: cy)?.usingColorSpace(.deviceRGB) else { continue }
            red += Double(c.redComponent); green += Double(c.greenComponent); blue += Double(c.blueComponent); used += 1
        }
        guard used > 0 else { return .systemPurple }
        return NSColor(calibratedRed: max(0.20, red/used), green: max(0.22, green/used), blue: max(0.30, blue/used), alpha: 1)
    }
}

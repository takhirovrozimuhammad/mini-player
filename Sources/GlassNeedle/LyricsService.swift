import Foundation

struct LyricsService {
    static func fetch(for track: TrackSnapshot, completion: @escaping ([LyricLine]) -> Void) {
        var endpoint = URLComponents(string: "https://lrclib.net/api/get")!
        endpoint.queryItems = [
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "track_name", value: track.title),
            URLQueryItem(name: "album_name", value: track.album),
            URLQueryItem(name: "duration", value: String(Int(track.duration)))
        ]
        guard let url = endpoint.url else { completion([]); return }
        request(url) { data in
            let parsed: [String: Any]? = data.flatMap {
                try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
            }
            let matched = parsed?["syncedLyrics"] as? String
            if let matched, !matched.isEmpty {
                completion(parse(matched))
            } else {
                // The strict endpoint often misses tracks with different album/version names.
                search(track: track, completion: completion)
            }
        }
    }

    private static func search(track: TrackSnapshot, completion: @escaping ([LyricLine]) -> Void) {
        var endpoint = URLComponents(string: "https://lrclib.net/api/search")!
        endpoint.queryItems = [
            URLQueryItem(name: "artist_name", value: track.artist),
            URLQueryItem(name: "track_name", value: track.title)
        ]
        guard let url = endpoint.url else { completion([]); return }
        request(url) { data in
            guard let data,
                  let candidates = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                completion([]); return
            }
            let matches = candidates.filter { ($0["syncedLyrics"] as? String)?.isEmpty == false }
            let preferred = matches.min { left, right in
                let a = abs((left["duration"] as? Double ?? 0) - track.duration)
                let b = abs((right["duration"] as? Double ?? 0) - track.duration)
                return a < b
            }
            completion(preferred.flatMap { $0["syncedLyrics"] as? String }.map(parse) ?? [])
        }
    }

    private static func request(_ url: URL, completion: @escaping (Data?) -> Void) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 9
        request.setValue("GlassNeedle/0.1 (macOS music companion)", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { data, _, _ in completion(data) }.resume()
    }

    static func parse(_ text: String) -> [LyricLine] {
        guard let pattern = try? NSRegularExpression(pattern: #"^\[(\d+):(\d+(?:\.\d+)?)\](.*)$"#) else { return [] }
        return text.split(whereSeparator: \.isNewline).compactMap { line in
            let raw = String(line)
            let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
            guard let match = pattern.firstMatch(in: raw, range: range), match.numberOfRanges == 4,
                  let minRange = Range(match.range(at: 1), in: raw),
                  let secRange = Range(match.range(at: 2), in: raw),
                  let bodyRange = Range(match.range(at: 3), in: raw),
                  let minutes = Double(raw[minRange]),
                  let seconds = Double(raw[secRange]) else { return nil }
            let body = String(raw[bodyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty else { return nil }
            return LyricLine(time: minutes * 60 + seconds, text: body)
        }.sorted { $0.time < $1.time }
    }
}

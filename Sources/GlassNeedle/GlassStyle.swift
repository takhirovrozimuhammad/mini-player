import SwiftUI
import AppKit

extension Color {
    init(ns: NSColor) { self.init(nsColor: ns) }
}

struct GlassSurface: ViewModifier {
    var radius: CGFloat = 24
    var intensity: Double = 0.68

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.32 * intensity), lineWidth: 0.9))
                .shadow(color: .black.opacity(0.28), radius: 22, y: 12)
        } else {
            content
                .background(.regularMaterial, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.25 * intensity), lineWidth: 0.8))
                .shadow(color: .black.opacity(0.28), radius: 22, y: 12)
        }
    }
}

extension View {
    func glassSurface(radius: CGFloat = 24, intensity: Double = 0.68) -> some View {
        modifier(GlassSurface(radius: radius, intensity: intensity))
    }
}

struct AccentAmbient: View {
    let accent: Color
    var brightness: Double = 1
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(accent.opacity(0.34 * brightness))
                    .frame(width: geo.size.width * 0.68)
                    .blur(radius: 82)
                    .offset(x: -geo.size.width * 0.24, y: geo.size.height * 0.15)
                Circle().fill(accent.opacity(0.20 * brightness))
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 94)
                    .offset(x: geo.size.width * 0.28, y: -geo.size.height * 0.18)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
    }
}

struct AlbumCover: View {
    let image: NSImage?
    var size: CGFloat = 96
    var radius: CGFloat = 15
    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [.init(red:0.19,green:0.13,blue:0.35),
                                             .init(red:0.46,green:0.33,blue:0.73),
                                             .init(red:0.06,green:0.12,blue:0.23)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Circle().stroke(.white.opacity(0.24), lineWidth: 1)
                        .frame(width: size * 0.62, height: size * 0.62)
                    Image(systemName: "waveform").font(.system(size: size * 0.22, weight: .light))
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(.white.opacity(0.20), lineWidth: 0.7))
    }
}

struct VinylRecord: View {
    @ObservedObject var media: MediaStore
    @ObservedObject var settings: GlassSettings
    var diameter: CGFloat = 180
    private var color: Color {
        settings.accent == .album ? Color(ns: media.artworkColor) : Color(ns: settings.accent.color)
    }
    var body: some View {
        TimelineView(.periodic(from: .now,
                               by: settings.reducedMotion || media.track?.playing != true ? 1 : 1.0 / 24)) { _ in
            ZStack {
                Circle().fill(
                    RadialGradient(colors: [.black,.init(white:0.15),.black,.init(white:0.09),.black],
                                   center: .center, startRadius: 0, endRadius: diameter/2))
                ForEach(0..<12, id: \.self) { i in
                    Circle().stroke(.white.opacity(i.isMultiple(of: 2) ? 0.085 : 0.042), lineWidth: 0.8)
                        .padding(CGFloat(i) * 5 + 12)
                }
                Circle().stroke(color.opacity(0.25), lineWidth: 1).padding(diameter * 0.12)
                AlbumCover(image: media.artwork, size: diameter * 0.39, radius: diameter * 0.20)
                    .clipShape(Circle())
                Circle().fill(.white.opacity(0.95)).frame(width: 6, height: 6)
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .rotationEffect(.degrees(settings.reducedMotion ? 0 : media.progress * 200))
            .shadow(color: .black.opacity(0.6), radius: 14, y: 8)
            .overlay(Circle().stroke(.white.opacity(0.09), lineWidth: 1))
        }
    }
}

struct TrackProgress: View {
    @ObservedObject var media: MediaStore
    @State private var draggingProgress: Double?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
            let duration = max(1, media.track?.duration ?? 1)
            let actual = draggingProgress ?? media.progress
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.17))
                        Capsule().fill(.white.opacity(0.93))
                            .frame(width: max(2, geometry.size.width * min(1, max(0, actual/duration))))
                    }
                    .frame(height: 3)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            draggingProgress = max(0, min(duration, Double(value.location.x / max(1, geometry.size.width)) * duration))
                        }
                        .onEnded { value in
                            let newTime = max(0, min(duration, Double(value.location.x / max(1, geometry.size.width)) * duration))
                            draggingProgress = nil
                            media.perform(.seek(newTime))
                        })
                }
                .frame(height: 9)
                HStack {
                    Text(format(actual)).monospacedDigit()
                    Spacer()
                    Text("−" + format(duration - actual)).monospacedDigit()
                }
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            }
        }
    }
    private func format(_ time: Double) -> String {
        let t = max(0, Int(time))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}

struct MediaButtons: View {
    @ObservedObject var media: MediaStore
    var buttonSize: CGFloat = 16
    var body: some View {
        HStack(spacing: 25) {
            button("backward.end.fill", .previous)
            button(media.track?.playing == true ? "pause.fill" : "play.fill", .playPause, big: true)
            button("forward.end.fill", .next)
        }
    }
    private func button(_ symbol: String, _ action: MediaAction, big: Bool = false) -> some View {
        Button { media.perform(action) } label: {
            Image(systemName: symbol)
                .font(.system(size: big ? buttonSize * 1.25 : buttonSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol)
    }
}

struct SynchronizedLyrics: View {
    @ObservedObject var media: MediaStore
    var maxLines = 5
    var fontSize: CGFloat = 19
    var centered = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
            let index = media.lyricIndex(at: media.progress)
            VStack(alignment: centered ? .center : .leading, spacing: 14) {
                if media.lyrics.isEmpty {
                    Text(media.isFetching ? "Finding synced lyrics…" : "No synced lyrics for this track")
                        .font(.system(size: fontSize * 0.73, weight: .medium))
                        .foregroundStyle(.white.opacity(0.50))
                } else {
                    ForEach(Array(visibleIndices(centeredAt: index)), id: \.self) { i in
                        Text(media.lyrics[i].text)
                            .font(.system(size: i == index ? fontSize : fontSize * 0.79,
                                          weight: i == index ? .semibold : .medium,
                                          design: .rounded))
                            .foregroundStyle(.white.opacity(i == index ? 0.98 : 0.35))
                            .blur(radius: abs(i - index) > 1 ? 0.6 : 0)
                            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
                            .lineLimit(2)
                            .animation(.easeInOut(duration: 0.35), value: index)
                    }
                }
            }
        }
    }
    private func visibleIndices(centeredAt index: Int) -> Range<Int> {
        let start = max(0, index - 1)
        let end = min(media.lyrics.count, start + max(1, maxLines))
        return start..<end
    }
}

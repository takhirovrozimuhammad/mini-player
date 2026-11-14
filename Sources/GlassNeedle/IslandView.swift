import SwiftUI

struct IslandView: View {
    @ObservedObject var media: MediaStore
    @ObservedObject var settings: GlassSettings
    let onExpand: (Bool) -> Void
    let onSettings: () -> Void
    let onScan: () -> Void
    @State private var expanded = false
    @State private var scanPreview = false

    private var accent: Color {
        settings.accent == .album ? Color(ns: media.artworkColor) : Color(ns: settings.accent.color)
    }

    var body: some View {
        Group {
            if expanded { expandedPlayer } else { compactPlayer }
        }
        .glassSurface(radius: expanded ? 28 : 17, intensity: settings.glassOpacity)
        .overlay(alignment: .top) {
            // Optical highlight along the edge without covering the hardware camera notch.
            Capsule().fill(.white.opacity(0.14)).frame(width: expanded ? 190 : 100, height: 1)
                .padding(.top, 1)
        }
        .animation(settings.reducedMotion ? nil : .spring(response: 0.34, dampingFraction: 0.79), value: expanded)
        .onHover { hover in
            guard expanded != hover else { return }
            expanded = hover
            onExpand(hover)
        }
        .onTapGesture {
            guard !expanded else { return }
            expanded = true
            onExpand(true)
        }
    }

    private var compactPlayer: some View {
        HStack(spacing: 12) {
            AlbumCover(image: media.artwork, size: 23, radius: 6)
            Text(media.track?.title ?? "GLASSNEEDLE")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(.white)
            Spacer(minLength: 2)
            WaveformBars(color: accent, active: media.track?.playing == true && !settings.reducedMotion)
                .frame(width: 32, height: 15)
        }
        .padding(.horizontal, 13)
        .frame(width: 208, height: 35)
    }

    private var expandedPlayer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 13) {
                AlbumCover(image: media.artwork, size: 73, radius: 17)
                VStack(alignment: .leading, spacing: 6) {
                    Text(media.track?.title ?? "Nothing playing")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Text(media.track?.artist ?? "Open Spotify or Apple Music")
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.56)).lineLimit(1)
                    HStack(spacing: 6) {
                        Circle().fill(accent).frame(width: 5, height: 5)
                        Text(media.track?.source.rawValue ?? "STANDBY")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .tracking(1.5).foregroundStyle(.white.opacity(0.65))
                    }
                }
                Spacer()
                WaveformBars(color: accent, active: media.track?.playing == true && !settings.reducedMotion)
                    .frame(width: 52, height: 30)
            }
            TrackProgress(media: media)
            HStack {
                Button { onScan() } label: {
                    Label("Scan effect", systemImage: "faceid")
                        .labelStyle(.iconOnly).font(.system(size: 14))
                }
                .help("Visual Face ID-style animation only; does not unlock macOS")
                Spacer()
                MediaButtons(media: media, buttonSize: 15)
                Spacer()
                Button { onSettings() } label: {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 14))
                }
                .help("GlassNeedle settings")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.85))
            if settings.lyricsEnabled, media.lyrics.count > 0 {
                TimelineView(.periodic(from: .now, by: 0.4)) { _ in
                    let index = media.lyricIndex(at: media.progress)
                    Text(index >= 0 ? media.lyrics[index].text : "♪")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1).frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(17)
        .frame(width: 438)
        .background(AccentAmbient(accent: accent, brightness: 0.36).clipShape(RoundedRectangle(cornerRadius: 27)))
    }
}

struct WaveformBars: View {
    let color: Color
    var active = true
    var body: some View {
        TimelineView(.periodic(from: .now, by: active ? 1.0/15 : 1)) { tick in
            let t = tick.date.timeIntervalSince1970
            GeometryReader { geo in
                HStack(alignment: .center, spacing: 2.5) {
                    ForEach(0..<9, id: \.self) { i in
                        let motion = active ? abs(sin(t * (2.5 + Double(i%3)*0.7) + Double(i)*1.29)) : 0.15
                        Capsule().fill(color.opacity(0.55 + motion*0.45))
                            .frame(width: max(1.5, (geo.size.width - 20)/9),
                                   height: geo.size.height * (0.18 + motion * 0.80))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

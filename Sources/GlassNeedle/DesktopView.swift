import SwiftUI

struct DesktopWidgetView: View {
    @ObservedObject var media: MediaStore
    @ObservedObject var settings: GlassSettings
    private var accent: Color {
        settings.accent == .album ? Color(ns: media.artworkColor) : Color(ns: settings.accent.color)
    }

    var body: some View {
        ZStack {
            HStack(spacing: 27) {
                if settings.desktopStyle == .vinyl {
                    ZStack(alignment: .topTrailing) {
                        VinylRecord(media: media, settings: settings, diameter: 200)
                        TonearmView(progress: media.progress / max(1, media.track?.duration ?? 1))
                            .frame(width: 105, height: 150)
                            .offset(x: 14, y: -5)
                    }.frame(width: 222, height: 218)
                } else if settings.desktopStyle == .artwork {
                    AlbumCover(image: media.artwork, size: 207, radius: 21)
                }

                VStack(alignment: .leading, spacing: 13) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform").foregroundStyle(accent)
                        Text("NOW PLAYING").tracking(2.1)
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.67))

                    Text(media.track?.title ?? "Your music, reimagined")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .lineLimit(2).foregroundStyle(.white)
                    Text(media.track?.artist ?? "Play a song to begin")
                        .font(.system(size: 13)).foregroundStyle(.white.opacity(0.62))
                    TrackProgress(media: media)
                    HStack {
                        MediaButtons(media: media, buttonSize: 15)
                        Spacer()
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                    }
                    if settings.lyricsEnabled {
                        Divider().overlay(.white.opacity(0.08))
                        SynchronizedLyrics(media: media, maxLines: 2, fontSize: 13)
                            .frame(maxHeight: 54, alignment: .top)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
        .frame(width: 570, height: 270)
        .glassSurface(radius: 32, intensity: settings.glassOpacity)
        .padding(22)
    }
}

struct TonearmView: View {
    var progress: Double
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle().fill(.gray).frame(width: 21, height: 21)
                .overlay(Circle().stroke(.white.opacity(0.50), lineWidth: 1))
            Path { p in
                p.move(to: CGPoint(x: 95, y: 12))
                p.addLine(to: CGPoint(x: 70, y: 96))
                p.addLine(to: CGPoint(x: 48, y: 110))
            }
            .stroke(LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            Path { p in
                p.move(to: CGPoint(x: 48, y: 105))
                p.addLine(to: CGPoint(x: 35, y: 113))
            }
            .stroke(.gray, style: StrokeStyle(lineWidth: 10, lineCap: .round))
        }
        .rotationEffect(.degrees(-min(1, max(0, progress)) * 7), anchor: .topTrailing)
        .shadow(color: .black.opacity(0.6), radius: 5, y: 5)
        .allowsHitTesting(false)
    }
}

/// Optional wallpaper-level stage. It never handles clicks or impersonates the real lock screen.
struct DesktopStageView: View {
    @ObservedObject var media: MediaStore
    @ObservedObject var settings: GlassSettings
    private var accent: Color {
        settings.accent == .album ? Color(ns: media.artworkColor) : Color(ns: settings.accent.color)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if settings.useVideoWallpaper && !settings.videoPath.isEmpty {
                    LoopingVideoWallpaper(path: settings.videoPath)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .allowsHitTesting(false)
                }
                if settings.edgeGlow {
                    Rectangle()
                        .strokeBorder(accent.opacity(0.50), lineWidth: 2)
                        .blur(radius: 9)
                        .padding(5)
                    AccentAmbient(accent: accent, brightness: 0.36)
                }
                VStack(spacing: 12) {
                    if settings.clockEnabled {
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            VStack(spacing: 1) {
                                Text(timeline.date, format: .dateTime.weekday(.wide).day().month(.wide))
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                Text(timeline.date, format: .dateTime.hour().minute())
                                    .font(.system(size: min(geo.size.width * 0.105, 103), weight: .light, design: .rounded))
                                    .monospacedDigit()
                            }
                            .foregroundStyle(.white.opacity(0.88))
                            .shadow(color: .black.opacity(0.45), radius: 12)
                        }
                        .padding(.top, min(geo.size.height * 0.1, 92))
                    }
                    Spacer(minLength: 30)
                    if let current = media.track, settings.stageStyle != .minimal {
                        VStack(spacing: 13) {
                            if settings.desktopStyle == .vinyl {
                                VinylRecord(media: media, settings: settings, diameter: 134)
                            } else {
                                AlbumCover(image: media.artwork, size: 135, radius: 21)
                            }
                            VStack(spacing: 4) {
                                Text(current.title).font(.system(size: 15, weight: .semibold))
                                Text(current.artist).font(.system(size: 11)).foregroundStyle(.white.opacity(0.60))
                            }
                            if settings.lyricsEnabled && settings.stageStyle == .cinematic {
                                SynchronizedLyrics(media: media, maxLines: 4, fontSize: 22, centered: true)
                                    .frame(maxWidth: min(geo.size.width * 0.65, 750))
                                    .padding(.top, 20)
                            }
                        }
                        .shadow(color: .black.opacity(0.65), radius: 15)
                    }
                    Spacer(minLength: 80)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if settings.stageStyle == .constellation && settings.lyricsEnabled {
                    ConstellationWordsView(media: media, accent: accent,
                        lowMotion: settings.reducedMotion)
                        .frame(width: min(geo.size.width * 0.75, 1000), height: min(geo.size.height * 0.40, 330))
                        .offset(y: geo.size.height * 0.13)
                }
            }
            .allowsHitTesting(false)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.clear)
    }
}


/// Inspired by the geometric word constellation seen in the user's first video.
/// All geometry and SwiftUI drawing here are original to GlassNeedle.
struct ConstellationWordsView: View {
    @ObservedObject var media: MediaStore
    let accent: Color
    var lowMotion: Bool

    private let points: [CGPoint] = [
        .init(x:0.04,y:0.56), .init(x:0.13,y:0.36), .init(x:0.19,y:0.63),
        .init(x:0.31,y:0.22), .init(x:0.33,y:0.73), .init(x:0.43,y:0.48),
        .init(x:0.52,y:0.21), .init(x:0.57,y:0.65), .init(x:0.68,y:0.37),
        .init(x:0.75,y:0.79), .init(x:0.84,y:0.47), .init(x:0.93,y:0.25),
        .init(x:0.97,y:0.65)
    ]
    private let edges: [(Int,Int)] = [
        (0,1),(0,2),(1,2),(1,3),(1,4),(2,4),(3,4),(3,5),(3,6),
        (4,5),(4,7),(5,6),(5,7),(5,8),(6,8),(6,11),(7,8),(7,9),
        (8,9),(8,10),(8,11),(9,10),(9,12),(10,11),(10,12),(11,12)
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: lowMotion ? 1 : 0.15)) { timeline in
            let t = timeline.date.timeIntervalSince1970
            let idx = media.lyricIndex(at: media.progress)
            let current = idx >= 0 ? media.lyrics[idx].text : ""
            let words = current.split(separator: " ").map(String.init)
            GeometryReader { geo in
                ZStack {
                    Canvas { context, size in
                        for (i,j) in edges {
                            var path = Path()
                            path.move(to: CGPoint(x: points[i].x * size.width, y: points[i].y * size.height))
                            path.addLine(to: CGPoint(x: points[j].x * size.width, y: points[j].y * size.height))
                            context.stroke(path, with: .color(.white.opacity(0.26)), lineWidth: 0.7)
                        }
                        for (i,p) in points.enumerated() {
                            let pulse = lowMotion ? 0.5 : 0.45 + sin(t * 1.2 + Double(i)) * 0.3
                            let r = i.isMultiple(of: 4) ? 4.5 : 2.0
                            let dot = Path(ellipseIn: CGRect(x: p.x*size.width-r/2,
                                                               y: p.y*size.height-r/2,
                                                               width: r, height: r))
                            context.fill(dot, with: .color(.white.opacity(pulse + 0.2)))
                        }
                    }
                    ForEach(0..<min(8, words.count), id: \.self) { i in
                        Text(words[i])
                            .font(.system(size: i == min(7, words.count/2) ? 25 : 12,
                                          weight: i == min(7, words.count/2) ? .bold : .semibold,
                                          design: .rounded))
                            .foregroundStyle(i == 3 ? accent : .white)
                            .shadow(color: accent.opacity(0.35), radius: 12)
                            .position(x: points[(i+2) % points.count].x * geo.size.width,
                                      y: points[(i+2) % points.count].y * geo.size.height)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

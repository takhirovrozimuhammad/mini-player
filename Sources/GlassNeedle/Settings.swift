import Foundation
import Combine

@MainActor
final class GlassSettings: ObservableObject {
    private let defaults = UserDefaults.standard
    @Published var islandEnabled: Bool { didSet { persist() } }
    @Published var desktopEnabled: Bool { didSet { persist() } }
    @Published var stageEnabled: Bool { didSet { persist() } }
    @Published var lyricsEnabled: Bool { didSet { persist() } }
    @Published var clockEnabled: Bool { didSet { persist() } }
    @Published var edgeGlow: Bool { didSet { persist() } }
    @Published var alwaysOnTop: Bool { didSet { persist() } }
    @Published var reducedMotion: Bool { didSet { persist() } }
    @Published var launchAtLogin: Bool { didSet { persist() } }
    @Published var useVideoWallpaper: Bool { didSet { persist() } }
    @Published var videoPath: String { didSet { persist() } }
    @Published var demoMode: Bool { didSet { persist() } }
    @Published var glassOpacity: Double { didSet { persist() } }
    @Published var accent: AccentStyle { didSet { persist() } }
    @Published var desktopStyle: DesktopStyle { didSet { persist() } }
    @Published var stageStyle: StageStyle { didSet { persist() } }
    @Published var widgetX: Double { didSet { persist() } }
    @Published var widgetY: Double { didSet { persist() } }

    init() {
        func bool(_ key: String, _ fallback: Bool) -> Bool {
            UserDefaults.standard.object(forKey: key) as? Bool ?? fallback
        }
        islandEnabled = bool("islandEnabled", true)
        desktopEnabled = bool("desktopEnabled", true)
        stageEnabled = bool("stageEnabled", false)
        lyricsEnabled = bool("lyricsEnabled", true)
        clockEnabled = bool("clockEnabled", true)
        edgeGlow = bool("edgeGlow", true)
        alwaysOnTop = bool("alwaysOnTop", false)
        reducedMotion = bool("reducedMotion", false)
        launchAtLogin = bool("launchAtLogin", false)
        useVideoWallpaper = bool("useVideoWallpaper", false)
        videoPath = UserDefaults.standard.string(forKey: "videoPath") ?? ""
        demoMode = bool("demoMode", false)
        glassOpacity = UserDefaults.standard.object(forKey: "glassOpacity") as? Double ?? 0.68
        accent = AccentStyle(rawValue: UserDefaults.standard.string(forKey: "accent") ?? "") ?? .amethyst
        desktopStyle = DesktopStyle(rawValue: UserDefaults.standard.string(forKey: "desktopStyle") ?? "") ?? .vinyl
        stageStyle = StageStyle(rawValue: UserDefaults.standard.string(forKey: "stageStyle") ?? "") ?? .cinematic
        widgetX = UserDefaults.standard.object(forKey: "widgetX") as? Double ?? 0.72
        widgetY = UserDefaults.standard.object(forKey: "widgetY") as? Double ?? 0.24
    }

    private func persist() {
        defaults.set(islandEnabled, forKey: "islandEnabled")
        defaults.set(desktopEnabled, forKey: "desktopEnabled")
        defaults.set(stageEnabled, forKey: "stageEnabled")
        defaults.set(lyricsEnabled, forKey: "lyricsEnabled")
        defaults.set(clockEnabled, forKey: "clockEnabled")
        defaults.set(edgeGlow, forKey: "edgeGlow")
        defaults.set(alwaysOnTop, forKey: "alwaysOnTop")
        defaults.set(reducedMotion, forKey: "reducedMotion")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(useVideoWallpaper, forKey: "useVideoWallpaper")
        defaults.set(videoPath, forKey: "videoPath")
        defaults.set(demoMode, forKey: "demoMode")
        defaults.set(glassOpacity, forKey: "glassOpacity")
        defaults.set(accent.rawValue, forKey: "accent")
        defaults.set(desktopStyle.rawValue, forKey: "desktopStyle")
        defaults.set(stageStyle.rawValue, forKey: "stageStyle")
        defaults.set(widgetX, forKey: "widgetX")
        defaults.set(widgetY, forKey: "widgetY")
    }
}

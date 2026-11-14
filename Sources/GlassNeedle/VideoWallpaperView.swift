import SwiftUI
import AVFoundation
import AppKit

/// A muted, looping user-selected local video drawn in the non-interactive desktop stage.
/// This is not the secure macOS lock screen or a system wallpaper replacement.
final class WallpaperPlayerView: NSView {
    private var player: AVPlayer?
    private var videoLayer: AVPlayerLayer?
    private var endObserver: NSObjectProtocol?
    private var loadedURL: URL?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    func configure(url: URL) {
        guard loadedURL != url else { return }
        tearDown()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        loadedURL = url
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none
        let visual = AVPlayerLayer(player: player)
        visual.videoGravity = .resizeAspectFill
        visual.frame = bounds
        layer?.addSublayer(visual)
        self.player = player
        videoLayer = visual
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak player] _ in
                player?.seek(to: .zero) { _ in player?.play() }
            }
        player.play()
    }

    override func layout() {
        super.layout()
        videoLayer?.frame = bounds
    }

    func tearDown() {
        player?.pause()
        if let observer = endObserver { NotificationCenter.default.removeObserver(observer) }
        endObserver = nil
        videoLayer?.removeFromSuperlayer()
        videoLayer = nil
        player = nil
        loadedURL = nil
    }
    deinit {
        // NSView lifetime owns its player; prevent an orphan playback session.
        player?.pause()
        if let observer = endObserver { NotificationCenter.default.removeObserver(observer) }
    }
}

struct LoopingVideoWallpaper: NSViewRepresentable {
    let path: String
    func makeNSView(context: Context) -> WallpaperPlayerView {
        let view = WallpaperPlayerView(frame: .zero)
        view.configure(url: URL(fileURLWithPath: path))
        return view
    }
    func updateNSView(_ nsView: WallpaperPlayerView, context: Context) {
        nsView.configure(url: URL(fileURLWithPath: path))
    }
    static func dismantleNSView(_ nsView: WallpaperPlayerView, coordinator: ()) {
        nsView.tearDown()
    }
}

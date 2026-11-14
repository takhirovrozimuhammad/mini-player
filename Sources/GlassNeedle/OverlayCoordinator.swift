import AppKit
import SwiftUI
import Combine
import CoreGraphics
import QuartzCore

@MainActor
final class OverlayCoordinator: NSObject, NSWindowDelegate {
    let settings: GlassSettings
    let media: MediaStore
    private var stagePanel: NSPanel?
    private var widgetPanel: NSPanel?
    private var islandPanel: NSPanel?
    private var scanPanel: NSPanel?
    private var settingsWindow: NSWindow?
    private var expanded = false
    private var subscription: AnyCancellable?

    init(settings: GlassSettings, media: MediaStore) {
        self.settings = settings
        self.media = media
        super.init()
        subscription = settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.refresh() }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func start() {
        createStage()
        createWidget()
        createIsland()
        refresh()
    }

    @objc private func screenDidChange() { refresh() }

    private func screen() -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main ?? NSScreen.screens.first
    }
    private var desktopLevel: NSWindow.Level {
        NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
    }

    private func panel(frame: NSRect, level: NSWindow.Level) -> NSPanel {
        let p = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.level = level
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        p.hidesOnDeactivate = false
        p.animationBehavior = .none
        p.isReleasedWhenClosed = false
        return p
    }

    private func createStage() {
        guard let target = screen() else { return }
        let p = panel(frame: target.frame, level: desktopLevel)
        p.ignoresMouseEvents = true
        p.contentView = NSHostingView(rootView: DesktopStageView(media: media, settings: settings))
        stagePanel = p
    }

    private func createWidget() {
        guard let target = screen() else { return }
        let frame = target.visibleFrame
        let size = NSSize(width: 614, height: 314)
        let origin = NSPoint(x: frame.minX + (frame.width-size.width)*settings.widgetX,
                             y: frame.minY + (frame.height-size.height)*settings.widgetY)
        let p = panel(frame: NSRect(origin: origin, size: size), level: desktopLevel)
        p.isMovableByWindowBackground = true
        p.delegate = self
        p.contentView = NSHostingView(rootView: DesktopWidgetView(media: media, settings: settings))
        widgetPanel = p
    }

    private func createIsland() {
        guard let target = screen() else { return }
        let initialSize = NSSize(width: 210, height: 37)
        let p = panel(frame: NSRect(x: target.frame.midX-initialSize.width/2,
                                    y: target.frame.maxY-initialSize.height,
                                    width: initialSize.width, height: initialSize.height),
                      level: .statusBar)
        p.collectionBehavior.insert(.fullScreenAuxiliary)
        p.contentView = NSHostingView(rootView: IslandView(
            media: media, settings: settings,
            onExpand: { [weak self] isExpanded in self?.expandIsland(isExpanded) },
            onSettings: { [weak self] in self?.showSettings() },
            onScan: { [weak self] in self?.showScanPreview() }))
        islandPanel = p
    }

    private func expandIsland(_ yes: Bool) {
        guard let p = islandPanel, let target = screen() else { return }
        expanded = yes
        let size = yes ? NSSize(width: 442, height: 239) : NSSize(width: 210, height: 37)
        let targetFrame = NSRect(x: target.frame.midX-size.width/2,
                                 y: target.frame.maxY-size.height,
                                 width: size.width, height: size.height)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = settings.reducedMotion ? 0 : 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            p.animator().setFrame(targetFrame, display: true)
        }
    }

    func refresh() {
        guard let target = screen() else { return }
        stagePanel?.setFrame(target.frame, display: true)
        stagePanel?.level = desktopLevel
        if settings.stageEnabled { stagePanel?.orderFrontRegardless() } else { stagePanel?.orderOut(nil) }

        widgetPanel?.level = settings.alwaysOnTop ? .floating : desktopLevel
        if settings.desktopEnabled { widgetPanel?.orderFrontRegardless() } else { widgetPanel?.orderOut(nil) }

        if settings.islandEnabled {
            islandPanel?.orderFrontRegardless()
            let size = expanded ? NSSize(width: 442, height: 239) : NSSize(width: 210, height: 37)
            islandPanel?.setFrame(NSRect(x: target.frame.midX-size.width/2,
                                         y: target.frame.maxY-size.height,
                                         width: size.width, height: size.height), display: true)
        } else {
            islandPanel?.orderOut(nil)
        }
    }

    func showScanPreview() {
        // Deliberately an animation: no access to Face ID sensor, no OS login/unlock.
        guard let target = screen() else { return }
        scanPanel?.orderOut(nil)
        let size = NSSize(width: 110, height: 112)
        let p = panel(frame: NSRect(x: target.frame.midX-size.width/2,
                                    y: target.frame.maxY - size.height - 53,
                                    width: size.width, height: size.height), level: .statusBar)
        p.ignoresMouseEvents = true
        p.contentView = NSHostingView(rootView: ScanPreviewView())
        scanPanel = p
        p.orderFrontRegardless()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) { [weak self, weak p] in
            p?.orderOut(nil)
            if self?.scanPanel === p { self?.scanPanel = nil }
        }
    }

    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 780, height: 670),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "GlassNeedle • Studio"
        window.minSize = NSSize(width: 630, height: 510)
        window.contentView = NSHostingView(rootView: SettingsView(
            settings: settings, media: media, onScan: { [weak self] in self?.showScanPreview() }))
        window.center()
        window.isReleasedWhenClosed = false
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowDidMove(_ notification: Notification) {
        guard let p = notification.object as? NSWindow, p === widgetPanel,
              let frame = screen()?.visibleFrame else { return }
        settings.widgetX = max(0, min(1, (p.frame.minX - frame.minX)/max(1, frame.width-p.frame.width)))
        settings.widgetY = max(0, min(1, (p.frame.minY - frame.minY)/max(1, frame.height-p.frame.height)))
    }
}

struct ScanPreviewView: View {
    @State private var fill = 0.0
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "faceid")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 41, weight: .thin))
                .foregroundStyle(Color.mint)
                .scaleEffect(fill == 0 ? 0.83 : 1.0)
            Text("VISUAL PREVIEW")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.85))
            Capsule().fill(Color.mint.opacity(0.80))
                .frame(width: max(4, fill * 65), height: 2)
                .frame(width: 65, alignment: .leading)
        }
        .frame(width: 98, height: 100)
        .glassSurface(radius: 25)
        .padding(6)
        .onAppear { withAnimation(.easeInOut(duration: 1.2)) { fill = 1 } }
    }
}

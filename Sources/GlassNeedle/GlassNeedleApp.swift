import AppKit
import SwiftUI
import Combine

@main
struct GlassNeedleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = GlassSettings()
    private lazy var media = MediaStore(settings: settings)
    private lazy var overlays = OverlayCoordinator(settings: settings, media: media)
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var settingsSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        overlays.start()
        media.start()
        settingsSubscription = settings.$demoMode.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.media.refresh() }
        }
    }

    private func configureMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "opticaldisc", accessibilityDescription: "GlassNeedle")
            button.toolTip = "GlassNeedle • Music studio"
        }
        menu.delegate = self
        statusItem?.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        let heading = NSMenuItem(title: "GlassNeedle  ·  0.1 Preview", action: nil, keyEquivalent: "")
        heading.isEnabled = false
        menu.addItem(heading)
        menu.addItem(.separator())
        add("Open Studio / Settings", selector: #selector(openSettings))
        add(settings.islandEnabled ? "✓  Glass Island" : "    Glass Island", selector: #selector(toggleIsland))
        add(settings.desktopEnabled ? "✓  Desktop player" : "    Desktop player", selector: #selector(toggleDesktop))
        add(settings.stageEnabled ? "✓  Cinematic desktop stage" : "    Cinematic desktop stage", selector: #selector(toggleStage))
        add(settings.demoMode ? "✓  Demo preview" : "    Demo preview", selector: #selector(toggleDemo))
        menu.addItem(.separator())
        add("Face scan animation (visual)", selector: #selector(scan))
        add("Test biometric approval", selector: #selector(biometrics))
        menu.addItem(.separator())
        add("Quit GlassNeedle", selector: #selector(quit), key: "q")
    }

    private func add(_ title: String, selector: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    @objc private func openSettings() { overlays.showSettings() }
    @objc private func toggleIsland() { settings.islandEnabled.toggle() }
    @objc private func toggleDesktop() { settings.desktopEnabled.toggle() }
    @objc private func toggleStage() { settings.stageEnabled.toggle() }
    @objc private func toggleDemo() { settings.demoMode.toggle() }
    @objc private func scan() { overlays.showScanPreview() }
    @objc private func biometrics() {
        SecureAction.authenticate { success, message in
            let alert = NSAlert()
            alert.messageText = success ? "Verified with macOS" : "Authentication not completed"
            alert.informativeText = message
            alert.runModal()
        }
    }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { media.stop() }
}

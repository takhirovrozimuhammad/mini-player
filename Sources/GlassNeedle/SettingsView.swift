import SwiftUI
import ServiceManagement
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settings: GlassSettings
    @ObservedObject var media: MediaStore
    let onScan: () -> Void
    @State private var authenticationMessage = ""

    private var accentColor: Color {
        settings.accent == .album ? Color(ns: media.artworkColor) : Color(ns: settings.accent.color)
    }

    var body: some View {
        ZStack {
            Color(red: 0.045, green: 0.045, blue: 0.08)
            AccentAmbient(accent: accentColor, brightness: 0.6)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "opticaldisc.fill")
                            .font(.system(size: 36)).foregroundStyle(accentColor)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("GlassNeedle").font(.system(size: 29, weight: .bold, design: .rounded))
                            Text("YOUR DESKTOP. YOUR MUSIC. YOUR GLASS.")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .tracking(2).foregroundStyle(.white.opacity(0.47))
                        }
                        Spacer()
                        Text("PREVIEW 0.1")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                            .padding(9).glassSurface(radius: 12)
                    }
                    .padding(.bottom, 9)

                    section("Surfaces", icon: "square.3.layers.3d") {
                        toggle("Glass Dynamic Island", sub: "Notch hover player, music controls & waveform", value: $settings.islandEnabled)
                        toggle("Desktop music widget", sub: "Interactive card directly above the wallpaper", value: $settings.desktopEnabled)
                        toggle("Cinematic desktop stage", sub: "Big clock, centered lyrics and wallpaper glow", value: $settings.stageEnabled)
                        toggle("Show synchronized lyrics", sub: "LRCLIB fetches lyrics for supported tracks", value: $settings.lyricsEnabled)
                        toggle("Large desktop clock", sub: "Shown when Cinematic stage is enabled", value: $settings.clockEnabled)
                    }
                    section("Glass appearance", icon: "circle.hexagongrid.fill") {
                        HStack {
                            Text("Theme"); Spacer()
                            Picker("", selection: $settings.accent) {
                                ForEach(AccentStyle.allCases) { style in Text(style.rawValue).tag(style) }
                            }.frame(width: 210)
                        }
                        HStack {
                            Text("Desktop player"); Spacer()
                            Picker("", selection: $settings.desktopStyle) {
                                ForEach(DesktopStyle.allCases) { style in Text(style.rawValue).tag(style) }
                            }.frame(width: 210)
                        }
                        HStack {
                            Text("Glass intensity")
                            Slider(value: $settings.glassOpacity, in: 0.25...1.0).tint(accentColor)
                            Text("\(Int(settings.glassOpacity*100))%")
                                .monospacedDigit().foregroundStyle(.white.opacity(0.55)).frame(width: 42)
                        }
                        HStack {
                            Text("Desktop cinematic style"); Spacer()
                            Picker("", selection: $settings.stageStyle) {
                                ForEach(StageStyle.allCases) { style in Text(style.rawValue).tag(style) }
                            }.frame(width: 210)
                        }
                        toggle("Desktop edge glow", sub: "Subtle luminous accents on cinematic stage", value: $settings.edgeGlow)
                        toggle("Loop a local video wallpaper", sub: "Muted video behind desktop lyrics; uses more battery", value: $settings.useVideoWallpaper)
                        HStack {
                            Text(settings.videoPath.isEmpty ? "No video selected" : URL(fileURLWithPath: settings.videoPath).lastPathComponent)
                                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                            Spacer()
                            Button("Choose MP4 / MOV") {
                                let picker = NSOpenPanel()
                                picker.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
                                picker.allowsMultipleSelection = false
                                if picker.runModal() == .OK, let url = picker.url {
                                    settings.videoPath = url.path
                                    settings.useVideoWallpaper = true
                                    settings.stageEnabled = true
                                }
                            }
                        }
                        toggle("Reduce animation", sub: "Lower update frequency and avoid bouncy transitions", value: $settings.reducedMotion)
                    }
                    section("Behavior", icon: "slider.horizontal.3") {
                        toggle("Float widget above all windows", sub: "Off means wallpaper-level, like native desktop widgets", value: $settings.alwaysOnTop)
                        toggle("Demo music", sub: "Preview design without starting Spotify or Music", value: $settings.demoMode)
                        toggle("Launch at login", sub: "Available after installing the bundled .app", value: $settings.launchAtLogin)
                            .onChange(of: settings.launchAtLogin) { _, value in
                                do {
                                    if value { try SMAppService.mainApp.register() }
                                    else { try SMAppService.mainApp.unregister() }
                                } catch {
                                    authenticationMessage = "Login item: \(error.localizedDescription)"
                                }
                            }
                    }
                    section("Security & effects", icon: "lock.shield") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Biometric approval").fontWeight(.medium)
                                Text("Real Touch ID / Apple Watch / password for app actions")
                                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.50))
                            }
                            Spacer()
                            Button("Test Touch ID") {
                                SecureAction.authenticate { ok, message in
                                    authenticationMessage = ok ? "Authenticated successfully" : message
                                }
                            }
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Face ID-style effect").fontWeight(.medium)
                                Text("Visual animation only. Cannot unlock the Mac.")
                                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.50))
                            }
                            Spacer()
                            Button("Preview") { onScan() }
                        }
                        if !authenticationMessage.isEmpty {
                            Text(authenticationMessage).font(.system(size: 11)).foregroundStyle(accentColor)
                        }
                    }
                    HStack {
                        Text("Native SwiftUI + AppKit · macOS 15+ · Real Liquid Glass on macOS 26+")
                        Spacer()
                        Text("Made for your Mac")
                    }
                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.38))
                    .padding(.bottom, 9)
                }
                .padding(30)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(.white)
        .frame(minWidth: 630, minHeight: 510)
    }

    private func section<Content: View>(_ name: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(name, systemImage: icon)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))
            Divider().overlay(.white.opacity(0.06))
            content()
        }
        .padding(21).frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(radius: 25, intensity: settings.glassOpacity)
    }

    private func toggle(_ title: String, sub: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(sub).font(.system(size: 11)).foregroundStyle(.white.opacity(0.49))
            }
            Spacer(minLength: 12)
            Toggle("", isOn: value).labelsHidden().tint(accentColor)
        }
    }
}

import SwiftUI
import NotchKit

/// The real camera housing remains a dead zone, NotchCutoutLayout puts art and
/// the live equalizer in usable screen pixels on either side of the notch.
struct NativeNotchCollapsed: View {
    @ObservedObject var media: MediaStore
    let presenter: NotchPresenter

    var body: some View {
        NotchCutoutLayout(
            cutoutWidth: presenter.geometry.hasPhysicalNotch ? presenter.geometry.notchWidth : 0,
            gutterWidth: presenter.collapsedGutterWidth,
            pillHeight: presenter.geometry.collapsedHeight,
            edgeInset: 7
        ) {
            AlbumCover(image: media.artwork, size: 23, radius: 5)
        } trailing: {
            WaveformBars(color: .mint, active: media.track?.playing == true)
                .frame(width: 23, height: 18)
        }
    }
}

struct NativeNotchExpanded: View {
    @ObservedObject var media: MediaStore
    @ObservedObject var settings: GlassSettings
    let showSettings: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            HStack(spacing: 14) {
                AlbumCover(image: media.artwork, size: 68, radius: 13)
                VStack(alignment: .leading, spacing: 4) {
                    Text(media.track?.title ?? "No music playing")
                        .font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    Text(media.track?.artist ?? "Open Spotify or Apple Music")
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                    Text(media.track?.source.rawValue ?? "READY")
                        .font(.system(size: 9)).tracking(2)
                        .foregroundStyle(.mint)
                }
                Spacer()
                Button(action: showSettings) {
                    Image(systemName: "slider.horizontal.3")
                }.buttonStyle(.plain)
            }
            TrackProgress(media: media)
            HStack {
                Spacer()
                MediaButtons(media: media, buttonSize: 17)
                Spacer()
            }
            if settings.lyricsEnabled {
                SynchronizedLyrics(media: media, maxLines: 2, fontSize: 12)
                    .frame(height: 36)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .foregroundStyle(.white)
    }
}

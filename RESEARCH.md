# GitHub research / source mapping — 2026-11-14

The following public repositories were checked for feature approaches. **They are references, not embedded or vendored source code.** GlassNeedle implementation was authored separately.

| Concern | Reference | License / caution |
|---|---|---|
| Original Needle product feature description | https://needlemac.com/ | Commercial app; no source imported |
| Dynamic Island architecture | https://github.com/bring-shrubbery/dynamic-landing | MIT; geometry coordination / notch morphology |
| Desktop vinyl / wallpaper panels | https://github.com/app-dialect/vinyl | MIT; desktop window / platter architecture |
| Interactive Spotify vinyl widget | https://github.com/kiss42/vinyl-widget | MIT; AppleScript and desktop placement |
| Spotify/Apple Music native floating widgets | https://github.com/aalemoro/Rota | License must be verified before importing code; Apple Music lyrics/UI |
| Notch and true glass look | https://github.com/techuila/top-notch | Verify license before any reuse; macOS26-native glass |
| Lyrics rendering approach | https://github.com/kernoeb/mac-now-playing | MIT; overlays and LRCLIB |
| Extra lyrics implementation | https://github.com/malemalice/floating-lyrics | Verify license before any reuse |
| Boring Notch | https://github.com/TheBoredTeam/boring.notch | GPL-3.0 — do not mix into a closed-source codebase |
| Atoll | https://github.com/Ebullioscopic/Atoll | GPL-3.0 — do not mix into a closed-source codebase |
| macOS authentication semantics | https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthentication | macOS uses Touch ID / Apple Watch / password, not built-in Face ID |

## Differences between user references and actual source

**User screenshots** (needlemac.com): show (1) vinyl and playback card on apparent lock screen; (2) album art plus translucent controls; (3) split layout with synced lyrics; (4) Boring Notch's dark player. Visual matches implemented in desktop-level stage and widget.

**Video 1** (~18.4 seconds, 720×1280): big clock, animated car / dark purple video behind, moving lyric words arranged on constellation-like lines, luminous border. Built as `DesktopStageView` (clock/edge glow), `ConstellationWordsView` and optional `LoopingVideoWallpaper`; **the same original footage is not included**.

**Video 2** (~10.4 seconds, 720×1280): music-aware notch, expanded glass player, apparent Face ID scan visual, artwork/lyrics/turntable on desktop. Built as `IslandView`, `ScanPreviewView`, `DesktopWidgetView`, `VinylRecord`, `SynchronizedLyrics`. The scan visual is not biometric authentication or Mac unlock.

## Platform limitations

- Normal apps cannot replace macOS's protected login/lock screen or grant themselves login/unlock capabilities.
- MacBook Air M2 has no Face ID hardware. LocalAuthentication supports Touch ID / Apple Watch / account password, for **app actions**, not unlocking the machine.
- Spotify and Apple Music AppleScript can vary by version; permissions and player running state matter.
- macOS 26 native `glassEffect` needs the relevant SDK. On macOS 15, use translucent material instead.
- Apple private MediaRemote framework is deliberately not used in this preview to avoid fragile/brittle private API coupling.
- AppKit desktop-level window placement should be tested on actual Mac hardware and different Spaces / displays.

## License handling

Only original GlassNeedle code and generated artwork are bundled. GPL reference repos remain separate. If future implementation *copies* MIT project files, retain their license and attribution. For GPL code, consult GPL obligations first.

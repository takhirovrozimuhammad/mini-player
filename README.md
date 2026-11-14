# GlassNeedle — Mac uchun native music experience

**v0.3 preview:** integrates three MIT-licensed projects, with three distinct island modes. Test the actual GitHub Actions build before installing.

### Island modes
1. Hardware notch — NotchKit measures actual display cutout; Side wings are adjustable.
2. Floating island — uses DynamicLanding screen metrics; adjustable width, gap and horizontal position.
3. Hover reveal — the panel appears when the pointer remains at the top centre for 1 second; delay is adjustable.

Actual Mac Face ID unlock and drawing inside macOS's secure Lock Screen are not supported. See THIRD_PARTY_NOTICES.md for integrated licenses.

GlassNeedle — yuborilgan Needle/Boring Notch skrinshotlari va ikkita videodagi g'oyalardan ilhomlangan, **original** SwiftUI + AppKit dasturi. Bu Needle'ning rasmiy kodi yoki Needle bilan bog'liq mahsulot emas. Githubdagi GPL-3.0 kodlari bu loyihaga ko'chirilmagan.

## Qanday o'rnatiladi (MacBook Air M2)

**Talablar:** macOS 15+; eng yangi Liquid Glass uchun **macOS 26+ va mos macOS SDK (Xcode 26+)**. Swift/Xcode Command Line Tools kerak. Internet: lyrics va rasm izlash uchun.

1. ZIPni oching va `GlassNeedle` papkasiga o'ting.
2. Terminalni oching, shu papkaga kirib quyidagini bajaring:

   ```bash
   xcode-select --install  # agar hali o'rnatilmagan bo'lsa
   bash scripts/build-app.sh
   open dist/GlassNeedle.app
   ```

3. Menu bar'da kichik plastinka belgisi paydo bo'ladi. **Open Studio / Settings** ni oching.
4. Avval **Demo preview** ni yoqing: hech qanday musiqa dasturisiz animatsiyalarni tekshirasiz.
5. Keyin Demo'ni o'chiring, Spotify yoki Apple Music'da qo'shiqni yoqing. macOS "Automation / Apple Events" ruxsatini so'rasa, kerakli dasturga ruxsat bering.
6. **Desktop cinematic stage** ni yoqsangiz, katta soat + lyrics sahnasini ko'rasiz. `Cinematic lyrics`, `Constellation words`, `Minimal clock` rejimlari bor.
7. `Choose MP4 / MOV` bilan shaxsiy videoni background sifatida tanlash mumkin. Bu GPU/batareya ishlatishini oshiradi.

> `bash scripts/build-app.sh` sizning Mac'ingizda ishga tushirilishi kerak. Chat muhiti Linux bo'lgani uchun bu yerda `.app` kompilyatsiyasini real Mac-da sinay olmadim. Agar xato chiqsa, Terminal xato matnini saqlang; aniq joyini tuzatish mumkin.

## Xususiyatlar ro'yxati

| Imkoniyat | Koddagi holati | Eslatma |
|---|---|---|
| Glass Dynamic Island | Implementatsiya bor | Hover → expanded, waveform, controls |
| macOS 26 native Liquid Glass | Implementatsiya bor | Older system: translucent material fallback |
| Desktop music widget | Implementatsiya bor | Wallpaper-level yoki floating |
| Aylanadigan vinyl | Implementatsiya bor | Groove + tonearm + album art |
| Spotify qo'shiqlari va boshqarish | Implementatsiya bor | AppleScript, Automation ruxsati |
| Apple Music qo'shiqlari va boshqarish | Implementatsiya bor | AppleScript, Automation ruxsati |
| Desktop soat | Implementatsiya bor | Cinematic stage |
| Synced lyrics | Implementatsiya bor | LRCLIB, katalogda bo'lmasa chiqmaydi |
| Lyrics constellation | Implementatsiya bor | Videodagi g'oyadan original geometrik animatsiya |
| Videofon | Implementatsiya bor | Shaxsiy MP4/MOV, muted, loop |
| Accent album rangiga moslashishi | Implementatsiya bor | Ranglari artwork'dan olinadi |
| Player music artwork | Implementatsiya bor | Spotify artwork URL / iTunes lookup fallback |
| Face ID ko'rinishidagi animatsiya | Implementatsiya bor | **Faqat vizual effekt** |
| Touch ID/Apple Watch/password approval | Implementatsiya bor | Faqat app ichidagi tasdiqlash |
| Native macOS login/lock screen ustiga UI | **Yo'q** | macOS secure login yuzasiga oddiy uchinchi tomon app rasm chiza olmaydi |
| Face ID bilan Mac-ni unlock qilish | **Mumkin emas** | MacBook Air M2 TrueDepth Face ID sensori yo'q |
| YouTube / browser media native bridge | **Yo'q** | Spotify va Apple Music public Apple Events ishlatilgan; MediaRemote private API ishlatilmagan |
| Ko'p-monitorning har biri uchun alohida overlay | **Yo'q** | Hozir bitta asosiy/aktiv monitor |
| Signed/notarized .dmg | **Yo'q** | Lokal ad-hoc app; tarqatish uchun Apple Developer ID kerak |

## Texnik tuzilma

- `GlassNeedleApp.swift`: main app va menu bar
- `OverlayCoordinator.swift`: notch, desktop widget, cinematic overlay, settings oynalari
- `IslandView.swift`: Dynamic Island va music UI
- `DesktopView.swift`: vinyl, lyrics, soat va constellation
- `VideoWallpaperView.swift`: loop'da ishlovchi mute AVPlayer background
- `GlassStyle.swift`: Liquid Glass, album art, record va controls
- `PlayerBridge.swift`: Spotify / Apple Music AppleScript
- `MediaStore.swift`: state, 1.5 sekundda media sync, artwork lookup
- `LyricsService.swift`: LRCLIB API, `.lrc` timestamp parser
- `Settings.swift`: saqlanadigan sozlamalar
- `SettingsView.swift`: shaffof studio UI
- `Security.swift`: native macOS LocalAuthentication
- `Resources/AppIcon.iconset`: original app icon
- `scripts/build-app.sh`: macOS `.app` bundle qilish
- `.github/workflows/build-macos.yml`: GitHub Actions macOS runner orqali `.app.zip` build

## Xavfsizlik va maxfiylik

- Camera ishlatilmaydi. Soxta Face ID tekshiruvi yoki kamera orqali yuzni aniqlash yo'q.
- `LAContext` faqat macOS'ning o'zida shaxsni tasdiqlaydi. Biometrik ma'lumot appga berilmaydi.
- Spotify / Apple Music ma'lumotlari AppleScript orqali o'qiladi. Ular ruxsatsiz ishlamasligi mumkin.
- Lyrics uchun qo'shiq nomi/artist `lrclib.net` bilan, artwork uchun esa kerak bo'lganda `itunes.apple.com` bilan ulashiladi. Bizning backend yo'q.
- Video faqat lokal kompyuterdan o'qiladi, serverga yuklanmaydi.
- Keraksiz Full Disk Access, Input Monitoring yoki Accessibility ruxsati talab qilinmaydi.

## Sinash ro'yxati (Mac kerak)

- [ ] `bash scripts/build-app.sh` macOS 26 SDK bilan compile bo'ladi
- [ ] App menu bar'da paydo bo'ladi
- [ ] Demo'da island/desktop/constellation ko'rinadi
- [ ] Spotify Automation ruxsati va playback test
- [ ] Apple Music Automation ruxsati va playback test
- [ ] LRCLIB qo'shiqda sinxronligi tekshiriladi
- [ ] Desktop-level layer Finder ikonlarini bosishga halal bermaydi
- [ ] Notch panel fullscreen Space almashganda to'g'ri turadi
- [ ] Video wallpaper pausalarda va display switch'da CPU/GPU tekshirilsin
- [ ] Touch ID approved action test

## Kodni o'zgartirish

`swift package generate-xcodeproj` eski va tavsiya qilinmaydi. Xcode'ning **File → Open...** menyusidan `Package.swift` ni ochish mumkin. `swift build` esa Terminal orqali ishlaydi.

## Litsenziya

Yozilgan GlassNeedle kodlari — MIT (`LICENSE` ga qarang). Bu paketga boshqa loyihalarning source fayllari ko'chirilmagan. GitHub reference loyihalar va ularning litsenziyalari `RESEARCH.md` da yozilgan.

## GitHub Releases — avtomatik `.dmg`

`scripts/build-dmg.sh` macOS'da `swift build -c release` orqali haqiqiy `.app`, keyin `hdiutil` orqali `.dmg`, `.zip` va SHA256 checksum faylini yaratadi. GitHub Actions `.github/workflows/build-macos.yml` `main`ga push bo'lganda yoki `v*` tag qo'yilganda macOS runner'da build qiladi. Build muvaffaqiyatli yakunlangandan keyin fayllar **Actions artifacts** va **Releases** bo'limiga joylanadi.

GitHub CLI (`gh`) o'rnatilgan va autentifikatsiyalangan Mac'da **oldindan yaratilgan, bo'sh** repository uchun `bash scripts/publish-github.sh OWNER/GlassNeedle` ishga tushiriladi. Skript mavjud GitHub tarixini buzmaslik uchun bo'sh bo'lmagan `main`ga push qilmaydi. `workflow_dispatch` qo'lda build boshlaydi, lekin Release avtomatik ochilishi uchun `main`ga push yoki `v*` tag kerak.

**Distribution limitation:** `.dmg` ad-hoc signed `.app`ni o'z ichiga oladi, Apple Developer ID bilan signed/notarized emas. macOS Gatekeeper tekshirishi va o'rnatishni cheklashi mumkin. Xavfsizlik himoyalarini chetlab o'tish tavsiya etilmaydi. Ishlab chiqarish tarqatilishi uchun Developer ID va notarization alohida sozlanishi kerak. Xcode/macOS'da compile va runtime tekshiruvlar hali zarur.

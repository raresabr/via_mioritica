## License

This project is licensed under **GPL-v3** (see `LICENSE`), because it depends
on `flutter_map_tile_caching` (FMTC) for offline map caching, which requires
any application using it to be distributed under the same license (unless a
proprietary license is purchased from the FMTC author). Since Via Mioritica
is a non-commercial/volunteer project, it is released as open source to
comply.

---

# Via Mioritica – Mobile App

Trail guide app for the Via Mioritica hiking route (Romania).  
Built with **Flutter 3.x** — single codebase for iOS + Android.

---

## Project structure

```
via_mioritica/
├── assets/
│   ├── data/stages.json          ← trail stage data (edit to add content)
│   ├── gpx/etapa-NN.gpx          ← GPX track per stage (replace placeholders!)
│   └── images/placeholders/      ← placeholder images (swap with real photos)
├── lib/
│   ├── main.dart                 ← app entry point (also initialises FMTC)
│   └── src/
│       ├── models/               ← StageModel, PoiModel, RecommendationModel, PhotoModel, AboutContentModel, UserModel/UserProgressModel (stubs)
│       ├── repositories/         ← abstract *Repository interfaces + LocalJson*/LocalGpx implementations (API-ready — see below)
│       ├── providers/            ← Riverpod providers (data layer + offline map state)
│       ├── screens/              ← RootNavScreen (5-tab nav), AboutScreen, FullTrailMapScreen, RecommendationsScreen, StagesListScreen/StageDetailScreen/MapScreen, PhotoGalleryScreen
│       ├── widgets/               ← TrailMap, ElevationChart, StageCard, PoiCard, OfflineDownloadCard, BrandFooter
│       └── utils/                ← AppTheme, AppColors, AppStrings, MapConfig
├── android/                      ← Android-specific config (compileSdk=37)
├── ios/                          ← iOS-specific config (NSLocationWhenInUse set)
├── LICENSE                       ← GPL-v3 (required by FMTC, see above)
├── .env                          ← secrets (GITIGNORED — never commit)
└── .env.example                  ← template, safe to commit
```

---

## First-time setup

### 1. Prerequisites
- Flutter 3.x SDK (`flutter doctor` should show ✓)
- Android Studio + emulator (or a physical device)
- Xcode (for iOS builds, macOS only)

### 2. Clone & install dependencies
```bash
git clone <repo-url>
cd via_mioritica
flutter pub get
```

### 3. Set up environment variables
```bash
cp .env.example .env
# Edit .env — fill in your MapTiler API key:
# MAPTILER_KEY=your_actual_key_here
```
Get a **free** MapTiler API key at https://www.maptiler.com/ (100k tile loads/month free).

### 4. Run on Android emulator
```bash
flutter run
```
Or from RubyMine: Run Configurations → Flutter → select the Android emulator.

### 5. Run on iOS simulator (macOS only)
```bash
flutter run -d "iPhone 15"
```

---

## Adding real content

### Add a new stage
1. Drop the GPX file into `assets/gpx/etapa-NN.gpx`
2. Register the asset path in `pubspec.yaml` under `assets:`
3. Add a JSON entry in `assets/data/stages.json` following the schema below
4. Run the app — stage appears automatically in the list

### Stage JSON schema
```json
{
  "id": "etapa-01",
  "name": "Etapa 1 – Start → End",
  "gpxFile": "assets/gpx/etapa-01.gpx",
  "distanceKm": 18.5,
  "elevationGainM": 850,
  "elevationLossM": 620,
  "difficulty": "Mediu",
  "durationEstimate": "6–8 ore",
  "description": "...",
  "coverImage": "assets/images/etapa-01-cover.webp",
  "pois": [
    {
      "id": "poi-01-01",
      "stageId": "etapa-01",
      "type": "cazare",
      "name": "Cabana XYZ",
      "lat": 46.5,
      "lon": 25.0,
      "description": "...",
      "photos": ["assets/images/etapa-01/cabana.webp"]
    }
  ]
}
```
`difficulty`: `Ușor` | `Mediu` | `Dificil`  
`type`: `cazare` | `popas` | `obiectiv` | `recomandare`

### Photo guidelines
- Resize to max 1600px longest side
- Save as WebP: `cwebp input.jpg -o output.webp`
- Register each new image directory in `pubspec.yaml`

---

## Repository architecture (API-readiness, Faza 7)

Every content type (stages, GPX, recommendations, photos, about) is accessed
through an **abstract repository interface**, never a concrete class:

```
StageRepository (interface)  →  LocalJsonStageRepository (reads assets/data/stages.json)
GpxRepository (interface)    →  LocalGpxRepository (parses GPX assets)
RecommendationRepository     →  LocalJsonRecommendationRepository (assets/data/recommendations.json)
PhotoRepository              →  LocalJsonPhotoRepository (assets/data/photos.json)
AboutRepository              →  LocalJsonAboutRepository (assets/data/about.json)
ProgressRepository (stub)    →  no implementation yet (Faza 15 builds the real local one)
```

Riverpod providers in `providers.dart` are typed against the **interface**
(e.g. `Provider<StageRepository>`), so swapping in a future
`ApiStageRepository` (Faza 17, hosted JSON) only requires changing the
provider's factory line — no screen or widget needs to change.

`UserModel`/`UserProgressModel` are stubs only (no backend, no login in the
MVP — see "Explicitly out of scope for MVP"); they exist so a future
account-backed `ProgressRepository` implementation has a concrete shape to
target.

---

## Cache-first content loading (Faza 13) + hosted JSON (Faza 17)

Every JSON-backed repository (`stages`, `recommendations`, `photos`, `about`
— **not** GPX, see below) routes its read through `CacheFirstLoader.load()`
(`lib/src/utils/cache_first_loader.dart`), backed by a single Hive box
(`ContentCacheBox`, initialised in `main.dart`):

1. **Cache HIT** (any launch after the first, or offline) → return the
   cached JSON **immediately**, no network wait, then fire off a
   background, unawaited revalidation request against the hosted URL
   (conditional GET with `If-None-Match`/ETag). If the hosted file
   changed, the cache is updated silently for the **next** cold start —
   this is what lets content update without a new app release, while
   every screen navigation within a session stays instant and
   network-free.
2. **Cache MISS** (first install, or cache cleared) → try a real HTTP GET
   against the hosted JSON (`ContentConfig.hostedUrlFor(...)`) first; on
   any failure (offline, DNS, timeout, non-200) fall back to the bundled
   JSON asset under `assets/data/` — the offline-first guarantee for a
   clean install with zero connectivity.

**Hosted content source**: the same JSON files committed under
`assets/data/*.json` in this repo, served raw via
`https://raw.githubusercontent.com/raresabr/via_mioritica/main/assets/data/*.json`
(`lib/src/utils/content_config.dart`). Single source of truth — editing a
JSON file in the repo and pushing to `main` updates the hosted content
within minutes (GitHub raw CDN cache ≈5 min), no separate CMS/backend, no
new app release for content-only changes. **Requires the repo to stay
public** (already the case — see License section; GPL-v3 requires public
source anyway).

**Change detection**: uses the HTTP `ETag` response header (GitHub sets one
per file automatically) instead of a hand-maintained "version" field inside
each JSON file — updates itself whenever content actually changes, with no
risk of a content editor forgetting to bump a version number.

Because every screen already reads content through Riverpod
`FutureProvider`s with `AsyncValue.when(loading: ..., ...)`, the network
fetch on cache miss automatically surfaces as a real loading spinner — no
extra UI plumbing was needed.

**GPX is intentionally excluded**: GPX tracks are bundled forever (no
API-hosted variant is planned, per "Explicitly out of scope"), so
`LocalGpxRepository` keeps its simple in-memory cache only.

---

## Secrets policy
- `.env` is **gitignored** — never commit it
- In CI: inject via `--dart-define=MAPTILER_KEY=$SECRET` instead of `.env`
- Rotate key immediately if accidentally committed

---

## Internal testing distribution

### Android — Firebase App Distribution
```bash
flutter build apk --release
# Upload app-release.apk to Firebase App Distribution
```

### iOS — TestFlight internal testers (instant, no App Store review)
```bash
flutter build ipa
# Xcode → Product → Archive → Distribute → TestFlight Internal Testing
```

---

## Tech stack
| Concern | Package |
|---|---|
| Maps | `flutter_map` |
| Offline map caching | `flutter_map_tile_caching` (FMTC, GPL-v3 — see License above) |
| GPS | `geolocator` + `permission_handler` |
| GPX parsing | `gpx` |
| Elevation chart | `fl_chart` |
| State management | `flutter_riverpod` |
| Env vars | `flutter_dotenv` |
| Coordinates | `latlong2` |

---

## Offline maps (FMTC corridor download)

Each stage's tiles are cached in its own FMTC store (`stage_<id>`), scoped to
a **corridor buffer** around the GPX track (`MapConfig.corridorBufferMeters`,
currently 3 km) at zoom levels `offlineMinZoom`–`offlineMaxZoom` — not the
whole country. This keeps downloads in the tens-to-low-hundreds of MB range
instead of gigabytes.

- Download/pause/resume/cancel/delete is exposed via `OfflineDownloadCard`
  on the stage detail screen, backed by `OfflineMapController`
  (`lib/src/providers/offline_map_providers.dart`).
- The estimated download size (MB) is shown to the user **before** starting,
  computed from `countTiles()` × average tile size.
- `TrailMap` automatically reads from the per-stage FMTC store first
  (`BrowseLoadingStrategy.cacheFirst`), then falls back to network — so a
  downloaded stage keeps working in airplane mode.
- **MapTiler ToS note**: MapTiler's Free plan is limited to non-commercial
  use (this project qualifies). If the project's status ever becomes
  commercial, re-check https://www.maptiler.com/cloud/pricing/ before
  shipping bulk offline downloads at scale.
- **iOS minimum deployment target: 15.0.** `objectbox_flutter_libs` (an FMTC
  dependency) requires iOS ≥15.0; the project previously defaulted to 13.0,
  which caused `pod install` to fail with "requires a higher minimum iOS
  deployment version" when building for a real device. Fixed in
  `ios/Podfile` (`platform :ios, '15.0'` + a `post_install` hook forcing
  `IPHONEOS_DEPLOYMENT_TARGET = 15.0` on every pod target) and in
  `ios/Runner.xcodeproj/project.pbxproj` (all 3 build configs). Verified with
  `flutter build ios --no-codesign --debug` (succeeds) — iOS 15 (2021) is a
  safe minimum given current device adoption.

---

## Navigation (Faza 8 — 5-tab bottom nav)

`RootNavScreen` (`lib/src/screens/root_nav_screen.dart`) is the app's home
after splash, with a `BottomNavigationBar` (`IndexedStack`, state preserved
across tab switches) and 5 tabs, in this fixed order:

1. **Despre Noi** (`AboutScreen`) — org content (placeholder for now) +
   `BrandFooter` linking to https://stag-line.com/.
2. **Hartă traseu** (`FullTrailMapScreen`) — the *entire* trail, all stages
   rendered simultaneously as colored polylines (`AppColors.colorForStageOrder`)
   with a tap-through legend. This is distinct from the per-stage map reached
   from "Ghidul Călătorului", which shows one segment with offline
   download + live GPS. The full-trail map uses plain online tiles (no FMTC
   override) — offline caching stays scoped per-stage.
3. **Recomandări practice** (`RecommendationsScreen`) — general hiking-safety
   tips from `assets/data/recommendations.json`.
4. **Ghidul Călătorului** (`StagesListScreen` → `StageDetailScreen` →
   `MapScreen`) — the original stage list/detail/map flow, reused as-is.
5. **Album foto** (`PhotoGalleryScreen`) — global photo gallery, filterable
   by stage (currently empty, `assets/data/photos.json` has structure only).

`home_screen.dart` was removed (superseded by `RootNavScreen`); the splash
screen now navigates to `RootNavScreen`.

---

## Segment colors (Faza 9)

Each stage/segment gets a deterministic color from `AppColors.segmentPalette`,
alternating **#870203** (dark red) / **#000000** (black) based on
`stage.order` (`AppColors.colorForStageOrder(order)`), consistently across:

- **Hartă traseu** (`FullTrailMapScreen`) — polyline per stage + legend
  swatches.
- **Ghidul Călătorului** — `StageCard` top accent stripe (stage list) and
  the single-stage polyline in `TrailMap` (used by both `MapScreen` and the
  compact preview in `StageDetailScreen`), via the new `TrailMap.segmentColor`
  parameter.

Both palette colors are dark, so they read clearly as accents on light card/
map backgrounds. Note: distinguishing red vs. black by color alone isn't
colorblind-safe — a text label/shortCode per segment (Faza 19) is planned to
address this; not yet implemented.

---

## Phase roadmap
- **Phase 0** ✅ Environment + project bootstrap
- **Phase 1** 🔄 Content structuring (add real GPX + JSON)
- **Phase 2** ✅ Offline map download (FMTC corridor caching)
- **Phase 3** ✅ GPS blue-dot (foreground, geolocator wired up)
- **Phase 4** ✅ Trail guide UI (stages, POIs, elevation chart, map)
- **Phase 5** ⬜ Polish + internal testing release
- **Phase 6** ⬜ Public store launch (later)
- **Phase 7** ✅ Repository interfaces + new content models (API-readiness)
- **Phase 8** ✅ 5-tab bottom navigation + full-trail map + branding footer
  (Faza 10 branding incidentally completed alongside `BrandFooter`)
- **Phase 9** ✅ Segment colors (#870203/#000000 alternating), consistent
  across full-trail map, legend, and Ghidul Călătorului
- **Phase 13** ✅ Cache-first content loading (Hive)
- **Phase 17** ✅ Hosted JSON (GitHub raw) replaces the simulated fetch;
  repo made public to serve it; ETag-based background revalidation


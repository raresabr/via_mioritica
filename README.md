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

### Bugfix: nested POI maps from Hive cache (post-Faza 17)

**Symptom**: "Hartă traseu" tab showed "Eroare la încărcarea datelor."
whenever `stagesProvider` read stage data back from the Hive cache (i.e.
any launch after the first, cache-HIT path).

**Root cause**: Hive round-trips JSON as `Map<dynamic, dynamic>`, not
`Map<String, dynamic>`. `LocalJsonStageRepository` already re-cast the
*top-level* stage map via `asStringKeyedMap()` before calling
`StageModel.fromJson`, but `StageModel.fromJson` itself cast each **nested**
`pois` list entry with a raw `p as Map<String, dynamic>` — which throws a
`type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String,
dynamic>'` cast error for any stage with non-empty `pois` once that data
came back through Hive instead of straight from `json.decode`.

**Fix**: moved the `asStringKeyedMap()` helper out of
`cache_first_loader.dart` into a neutral `lib/src/utils/json_utils.dart`
(still re-exported from `cache_first_loader.dart` for existing callers), and
made `StageModel.fromJson` call it on every nested POI map too, not just
the outer stage map. General lesson: any model with nested
maps/lists-of-maps must apply this re-cast recursively at **every** level,
not just the top one, whenever it might be hydrated from the Hive cache.

Verified: reproduced on the Android emulator (cleared app data, confirmed
crash with a temporary debug print of the exact exception/stack trace),
applied the fix, cleared app data again, and confirmed the "Hartă traseu"
tab now renders all 3 stage polylines + legend correctly with no error.

---

## Secrets policy
- `.env` is **gitignored** — never commit it
- In CI: inject via `--dart-define=MAPTILER_KEY=$SECRET` instead of `.env`
- Rotate key immediately if accidentally committed

---

## Internal testing distribution

### Android — Firebase App Distribution (Faza 11, formalized)

**One-time setup** (already done for this project — documented here for
reference/reproducibility on a new machine):
1. `npm install -g firebase-tools` + `firebase login` (interactive browser
   auth, once per machine).
2. Firebase project `via-mioritica-app` created (Spark/free plan), with an
   Android app (`ro.viamioritica.via_mioritica`) and iOS app
   (`ro.viamioritica.viaMioritica`) registered. Config files committed:
   `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
   (these contain a restricted client identifier, not a secret — standard
   Firebase practice to commit them; needed later for Fazele 14/16
   Remote Config/Crashlytics too, not used by App Distribution itself).
3. App Distribution "Get started" pressed once per app in the [Firebase
   console](https://console.firebase.google.com/project/via-mioritica-app/appdistribution)
   — this onboarding step **cannot** be done via CLI/API, console-only,
   one-time per app.
4. Tester group **"Testeri Interni"** (alias `testeri-interni`) created via
   `firebase appdistribution:group:create`, testers added via
   `firebase appdistribution:testers:add <emails> --group-alias testeri-interni`.

**Repeatable release flow** — `Makefile` at the repo root:
```bash
# Build the release APK only:
make build-android

# Upload an already-built APK to the "Testeri Interni" group:
make distribute-android

# Full flow in one command (release notes default to the latest git commit
# message, or pass your own):
make release-android NOTES="Fixed the map loading bug"
```
Testers get an email invite from Firebase with a link to install (Android
allows sideloading via the Firebase App Distribution tester app — no Play
Store needed for internal testing).

### iOS — TestFlight internal testers (requires paid Apple Developer Program)

⚠️ **Blocked for now**: both TestFlight and Firebase App Distribution for iOS
require a paid **Apple Developer Program membership ($99/year)** — this is
an Apple platform requirement, not a project limitation (no free tier
exists for either distribution channel). We currently only have a free
"Apple Development" signing identity, which allows direct-to-device runs via
Xcode/`flutter run` (cable or wireless, one device at a time, provisioning
profile expires after 7 days) but **cannot** produce a link-shareable build
for either TestFlight or Firebase App Distribution.

**Current iOS testing method** (until the paid account is purchased):
```bash
flutter run -d <device-id> --release   # direct install over cable/wifi
```

**Once the paid Apple Developer Program is active**, the flow becomes:
```bash
flutter build ipa
# Xcode → Product → Archive → Distribute → TestFlight Internal Testing
```
(Firebase App Distribution also supports iOS releases via
`firebase appdistribution:distribute <path>.ipa --app <iOS_APP_ID> --groups
testeri-interni`, using the same tester group already created — not wired
into the Makefile yet since TestFlight is the primary iOS channel per the
original plan; can be added as a `distribute-ios` target later if useful.)

---

## Android SDK versions (Faza 12, explicit decision)

`android/app/build.gradle.kts` no longer relies on Flutter's implicit
`flutter.minSdkVersion`/`flutter.targetSdkVersion` defaults — the values are
now hard-coded and documented, so a future Flutter upgrade can't silently
change device compatibility:

- **`compileSdk = 37`** — required by `permission_handler_android` (declares
  `compileSdk 37`); the highest requirement among current dependencies.
- **`minSdk = 24`** (Android 7.0) — required by `permission_handler_android`
  and `url_launcher_android` (both declare `minSdk 24`); matches Flutter's
  own current default, covers >98% of active Android devices (2026).
- **`targetSdk = 36`** — latest stable Android version supported by Flutter
  at the time of this decision; required by Google Play for new apps/updates.

---

## Force update via Remote Config (Faza 14)

Firebase Remote Config gates app usage on a minimum build number — used to
kill a shipped build with a critical bug (broken map/GPX parser, etc.)
without waiting for users to update on their own.

**How it works** (`lib/src/services/remote_config_service.dart`):
- On launch, `main.dart` initializes Firebase (`lib/firebase_options.dart`,
  generated by `flutterfire configure`) and calls
  `RemoteConfigService.init()`, which fetches+activates Remote Config
  (15 min minimum fetch interval, 10s timeout) and reads the current app's
  own build number via `package_info_plus`.
- `SplashScreen` checks `RemoteConfigService.isForceUpdateRequired`
  (installed build number < `min_supported_build_number` from Remote
  Config) and, if true, navigates to `ForceUpdateScreen` instead of
  `RootNavScreen` — a non-dismissible screen (`PopScope(canPop: false)`,
  no back-button escape) with an "Actualizează acum" button opening the
  platform store URL.
- **Fails open, never fails closed**: any Remote Config/network error
  (offline first launch, misconfigured project) just means the defaults
  apply — `min_supported_build_number` defaults to the app's *own* current
  build number, so a failed fetch can never force-block the app.
- Build-number comparison (not semver strings) is deliberate — a plain
  integer compare (`versionCode`/`CFBundleVersion`, from `pubspec.yaml`'s
  `version: x.y.z+<buildNumber>`) can't be thrown off by inconsistent
  version-string formatting.

**Remote Config parameters** (`remoteconfig.template.json`, deployed via
`firebase deploy --only remoteconfig --project via-mioritica-app`):
- `min_supported_build_number` — bump to the new release's build number to
  force everyone on an older build to update.
- `force_update_message` — editable per-incident without a new release.
- `android_store_url` / `ios_store_url` — store links opened by the
  update button (iOS one is a placeholder until the app is actually
  published — see the TestFlight blocker above).

**Setup performed** (one-time, already done for this project): registered
Firebase apps for both platforms via `flutterfire configure
--project=via-mioritica-app` (required the `xcodeproj` Ruby gem locally for
the iOS Xcode project edit); this wired `google-services` Gradle plugin
into `android/settings.gradle.kts`/`android/app/build.gradle.kts` and added
`GoogleService-Info.plist` to the iOS Xcode target. `firebase_core`,
`firebase_remote_config`, `package_info_plus` added to `pubspec.yaml`.

**Note — iOS build via CocoaPods, not SPM**: `objectbox_flutter_libs`
(FMTC dependency) doesn't support Swift Package Manager, so
`flutter config --no-enable-swift-package-manager` is set for this
project — `flutter build ios` resolves all iOS pods (including Firebase)
through CocoaPods instead. If Xcode's SPM dependency resolution is ever
re-enabled, expect a "Couldn't get the list of tags" resolution failure in
sandboxed/restricted-network environments; CocoaPods doesn't hit this.

### Triggering a force-update (admin runbook, no code/CLI needed)

The Firebase Console **is** the admin dashboard for this — no separate
tool was built, since Remote Config already ships with one and nobody but
the project owner needs access to it:

1. Go to the [Remote Config
   page](https://console.firebase.google.com/project/via-mioritica-app/config)
   for the `via-mioritica-app` project (Google login with access required).
2. Find the `min_supported_build_number` parameter → click the pencil
   (edit) icon.
3. Set its value to the **build number** of the release you want to force
   everyone off of, or higher — the number after the `+` in `pubspec.yaml`'s
   `version: x.y.z+<buildNumber>` (this is what becomes `versionCode` on
   Android / `CFBundleVersion` on iOS at build time). E.g. if `1.2.0+7` has
   the bug, set `min_supported_build_number` to `8` (or the build number of
   the fixed release once it's out) so every install below that gets
   blocked.
4. (Optional) Edit `force_update_message` to explain the specific incident
   to users.
5. Click **Publish changes** (top right). Takes effect for any app
   instance within ~15 minutes (`minimumFetchInterval` in
   `RemoteConfigService`) — sooner for anyone who force-closes and
   reopens the app.
6. To roll back / stop forcing the update, set `min_supported_build_number`
   back down to `1` (or any build number ≤ the lowest one still allowed)
   and publish again.

**No redeploy, no CLI, no new app release needed** — this is exactly what
Remote Config is for. `remoteconfig.template.json` in the repo only seeds
the *initial* defaults (useful for reproducing the project from scratch on
a new machine via `firebase deploy --only remoteconfig`); day-to-day
force-update triggers should go through the Console, not that file.

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
| Remote config / force update | `firebase_core` + `firebase_remote_config` |
| App version detection | `package_info_plus` |

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
- **Phase 10** ✅ Branding footer → stag-line.com (completed alongside
  Phase 8, verified separately end-to-end)
- **Phase 11** ✅ Firebase App Distribution formalized: named tester group
  ("Testeri Interni"), repeatable `Makefile` (`make release-android`)
- **Phase 12** ✅ Explicit Android `minSdk`/`targetSdk`/`compileSdk` decision
  (see "Android SDK versions" above)
- **Phase 14** ✅ Force-update via Firebase Remote Config (see below)


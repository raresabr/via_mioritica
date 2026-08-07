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

## Quick commands (most used, day-to-day)

```bash
# Run a debug/release build directly on a connected iPhone (cable). Find
# the device id first with `flutter devices`.
flutter run -d 00008110-001E1DE80CBA801E --release

# Build a fresh Android release APK (auto-bumps the build number in
# pubspec.yaml, e.g. 1.0.0+2 -> 1.0.0+3, so each build is distinct).
make build-android

# Upload the already-built APK to Firebase App Distribution, "Testeri
# Interni" group.
make distribute-android

# Both of the above in one go, with custom release notes:
make release-android NOTES="Fixed the map loading bug"
```
See "Internal testing distribution" below for full setup details and the
iOS/TestFlight equivalent.

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
│       ├── widgets/               ← TrailMap, StageCard, PoiCard, OfflineDownloadCard, BrandFooter
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
ProgressRepository (stub)    →  no implementation yet (account-backed sync, not built)
LocalProgressRepository      →  HiveProgressRepository (Faza 15, local-only, no account)
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
`make build-android` (and therefore `make release-android`) always runs
`make bump-build` first, which auto-increments the build number (the `+N`
after the version name) in `pubspec.yaml` — e.g. `1.0.0+2` → `1.0.0+3` →
`1.0.0+4` — so every release shows up as a distinct, incrementing build in
Firebase App Distribution without having to remember to bump it by hand.
The version *name* (`1.0.0`) is untouched by this — bump that manually in
`pubspec.yaml` only for real version changes.

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

## Local progress tracking (Faza 15)

Checkbox-per-stage + overall % completion, **local only, no account/login**
(consistent with "Explicitly out of scope for MVP" — see plan.md).

- `LocalProgressRepository` (interface, `lib/src/repositories/`) +
  `HiveProgressRepository` (implementation) — deliberately a **separate**
  abstraction from the account-based `ProgressRepository` stub (which keeps
  modeling a possible *future* API-backed sync via `userId`/
  `UserProgressModel`); this one has no user concept at all, just a set of
  completed stage IDs persisted in their own Hive box (`ProgressBox`,
  `user_progress` — kept apart from `ContentCacheBox` so clearing cached
  content can never wipe a user's actual hiking progress).
- `progress_providers.dart` — `ProgressController` (`StateNotifier<Set<String>>`)
  + `progressProvider`, so every screen watching it (list badge/%, detail
  checkbox) updates instantly on toggle.
- `StageDetailScreen` — "Marchează etapa ca finalizată" checkbox tile.
- `StageCard` — green checkmark badge on the cover image when a stage is
  completed.
- `StagesListScreen` — progress banner at the top ("X/Y etape finalizate",
  percentage + progress bar), computed live from `stagesProvider` ×
  `progressProvider`.

---

## Crash reporting + analytics (Faza 16)

Firebase Crashlytics (crash reporting) and Firebase Analytics (anonymous
usage), both routed through the same `via-mioritica-app` Firebase project
already wired up in Faza 14. Deliberately minimal scope, consistent with
"no account" (Faza 15): no PII is ever logged (no names, emails, GPS
coordinates) — only anonymous, aggregate signals.

- **`CrashlyticsService`** (`lib/src/services/crashlytics_service.dart`) —
  registers `FlutterError.onError` and
  `PlatformDispatcher.instance.onError` to forward uncaught Flutter/async
  errors to Crashlytics, plus a `recordNonFatal()` helper for caught
  errors worth surfacing without crashing. Disabled in debug builds
  (`kDebugMode`) so local `flutter run` sessions don't pollute the
  crash-free-users metric.
- **`AnalyticsService`** (`lib/src/services/analytics_service.dart`) —
  `FirebaseAnalyticsObserver` wired into `MaterialApp.navigatorObservers`
  for automatic screen-view tracking, plus two explicit events:
  `stage_completed` (stage id only, fired when a stage checkbox — Faza 15
  — is ticked on) and `force_update_shown` (fired when the Faza 14
  force-update gate actually blocks a real device — confirms a Remote
  Config push reaches users). Also disabled in debug builds.
- Both `init()` calls happen in `main()` right after
  `Firebase.initializeApp()`, and both fail open (try/catch, non-fatal) —
  an offline first launch just means no crash/analytics data for that
  session, never a blocked app.
- **Android**: `com.google.firebase.crashlytics` Gradle plugin added
  (`android/settings.gradle.kts` + `android/app/build.gradle.kts`);
  required bumping `com.google.gms.google-services` from `4.3.15` to
  `4.4.4` (Crashlytics Gradle plugin v3 requires Google Services ≥4.4.1).
- **iOS**: no extra config needed — deployment target is already 15.0
  (set for FMTC/ObjectBox in an earlier phase), which covers both new
  pods; `pod install` picks them up automatically via `firebase_core`.
- Verified: `flutter analyze` clean (same 8 pre-existing infos),
  `flutter build apk --debug` and `flutter build ios --no-codesign
  --debug` both succeed. Crash/event visibility in the Firebase console
  (real device test) is left to manual verification, as with all other
  phases.

---

## Privacy policy (Faza 18)

`PrivacyPolicyScreen` (`lib/src/screens/privacy_policy_screen.dart`) —
static, hardcoded Romanian text reachable from "Despre Noi" (link below the
main content, above the branding footer). **Deliberately hardcoded**, not
fetched from the hosted JSON like the rest of "Despre Noi" content — a
legal document shouldn't change silently via a background cache
revalidation (Faza 13/17) without a new app release/review.

Written to accurately describe what the app does as of Faza 16: no
account/login (consistent with Faza 15's local-only progress), GPS used
only live on-device (never stored/transmitted), Firebase Crashlytics
(automatic crash reports: error message, device model, OS/app version —
no name/email), Firebase Analytics (anonymous aggregate usage events —
screen views, `stage_completed`), locally-stored content cache + offline
maps, and third-party services used (Firebase/Google, MapTiler).

**Decision, per the plan's GDPR/ePrivacy note**: no consent banner was
added — all data collected (crash reports, anonymous analytics) is
non-personally-identifiable and the policy above documents it
transparently, which is deemed sufficient for this MVP's scope. Revisit if
future features add any PII collection (e.g. an account system).


---

## Tech stack
| Concern | Package |
|---|---|
| Maps | `flutter_map` |
| Offline map caching | `flutter_map_tile_caching` (FMTC, GPL-v3 — see License above) |
| GPS | `geolocator` + `permission_handler` |
| GPX parsing | `gpx` |
| State management | `flutter_riverpod` |
| Env vars | `flutter_dotenv` |
| Coordinates | `latlong2` |
| Remote config / force update | `firebase_core` + `firebase_remote_config` |
| Crash reporting | `firebase_crashlytics` |
| Analytics | `firebase_analytics` |
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
colorblind-safe — see Faza 19 below, which addresses this.

---

## Colorblind-safe segment labels (Faza 19)

`SegmentBadge` (`lib/src/widgets/segment_badge.dart`) — a small colored
circle with the segment's short text code (`E1`, `E2`, `E3`, ... — `E` for
"Etapa") inside it, from `AppColors.shortCodeForStageOrder(order)`. Reuses
the exact same deterministic `order` used by `colorForStageOrder`, so the
code and the color always agree. Replaces every place a segment's color
was previously shown **without** any accompanying text/shape, so users who
can't reliably tell #870203 (dark red) apart from #000000 (black) by hue
alone can still identify a segment:

- **`FullTrailMapScreen`** — legend swatches now show the badge (color +
  code) instead of a plain color dot; a badge marker is also placed at
  each polyline's midpoint directly on the map itself, so segments are
  identifiable without needing to cross-reference the legend below.
- **`StageCard`** — a badge in the top-left corner of the cover image
  (paired with the existing color accent stripe), on the stage list.
- **`StageDetailScreen`** / **`MapScreen`** — a badge next to the stage
  name in the app bar title.

---

## Offline download onboarding (Faza 20)

`OfflineOnboardingSheet` (`lib/src/widgets/offline_onboarding_sheet.dart`)
— a non-dismissible-by-swipe modal bottom sheet, shown **exactly once**,
the first time `RootNavScreen` builds (i.e. right after the splash
screen), explaining that mountain trails often have zero signal and
pointing users at the per-stage "Hartă offline" download feature (Faza
2b) *before* they start hiking, not after they discover the gap already
offline.

- **`SettingsBox`** (`lib/src/services/settings_box.dart`) — new, minimal
  Hive box for one-off local UI-state flags
  (`has_seen_offline_onboarding`). Deliberately separate from
  `ProgressBox` (Faza 15, actual hiking progress — never mixed with UI
  flags) and `ContentCacheBox` (Faza 13, disposable content cache — a
  settings flag must survive a cache clear).
- `OfflineOnboardingSheet.showIfFirstLaunch(context)` checks/sets the flag
  itself, so `RootNavScreen.initState()` (via
  `WidgetsBinding.instance.addPostFrameCallback`, for a valid
  `BuildContext`) can call it unconditionally on every app start.
- Verified: `flutter analyze` clean (same 8 pre-existing infos),
  `flutter build apk --debug` and `flutter build ios --no-codesign
  --debug` both succeed.

---

## Resumable offline downloads (Faza 21)

**Bug fixed first**: before this phase, `OfflineMapController._loadStats()`
only checked "are there any cached tiles at all?" to decide
`notDownloaded` vs. `complete` — so a download interrupted partway through
(app killed, crash, OS kills the process in the background) looked
identically **"complete"** next time the screen opened, even though most
tiles were still missing.

Fixed using FMTC's own built-in download-recovery system (`FMTCRoot.recovery`),
which already records a recovery entry (store name + last successful tile
index) whenever a download starts, and only clears it on a clean finish:

- **`OfflineMapRepository.getFailedRecovery(stageId)`** — looks up a
  "failed" recovery entry (i.e. one no longer actually running in memory —
  see FMTC's `RootRecovery` docs) matching this stage's store.
- **`OfflineMapRepository.regionFromRecovery(recovered)`** — converts it
  back into a `DownloadableRegion` whose `start` skips tiles already
  downloaded, so resuming re-fetches only the missing tiles, never the
  ones already saved.
- New `OfflineDownloadStatus.interrupted` state — `_loadStats()` now
  checks for a failed recovery *before* falling back to the old
  empty/complete check, and `OfflineDownloadCard` shows a distinct
  "Descărcarea a fost întreruptă..." message with a **"Reia descărcarea"**
  button (`OfflineMapController.resumeInterrupted()`) instead of silently
  claiming the download is done.
- `cancelAndDelete()` also discards the stale recovery entry (via
  `OfflineMapRepository.cancelRecovery(id)`) when the user chooses to
  delete/restart instead of resuming, so it can't resurface later.
- Verified: `flutter analyze` clean (same 8 pre-existing infos),
  `flutter build apk --debug` and `flutter build ios --no-codesign
  --debug` both succeed. Actually killing the app mid-download and
  confirming the resume flow end-to-end is left to manual device testing.

---

## UI/UX polish pass (post-Faza 21, user feedback)

A round of 6 UI/UX fixes requested directly by the user on already-shipped
screens — not a numbered "Faza" from the roadmap.

1. **Rough loading transition entering a stage** — `StageDetailScreen`
   used to render its whole layout instantly while `TrailMap` kept
   showing its own separate spinner in the map area a moment later. Now
   `StageDetailScreen` watches `trackPointsProvider(stage.gpxFile)` itself
   and shows a single simple loading screen (AppBar + centered spinner)
   until the GPX track is parsed, then builds the full layout in one
   shot — no more content "popping in" separately from the map.
2. **Mark stage completed directly from the list** — the top-right badge
   on `StageCard` (previously a static checkmark shown only when
   completed) is now always visible and tappable, calling
   `progressProvider.notifier.setCompleted(...)` directly — synced with
   the existing toggle inside `StageDetailScreen` via the same provider.
   It has its own `Material`/`InkWell` hit-test area so tapping it does
   not also trigger the card's navigation, plus `Semantics` labels for
   accessibility.
3. **Stronger visibility for completed stages** — `StageCard` now shows a
   green border + soft green shadow + a subtle green background tint
   when completed, in addition to the badge — the "done" state is
   obvious at a glance in a long list.
4. **Offline download card layout fix** — `OfflineDownloadCard`'s
   `notDownloaded`, `downloading`/`paused`, `interrupted`, `complete`,
   and `error` cases were all cramped `Row`s (long text + buttons on one
   line, clipping on narrow screens). Rewritten as `Column`s (text above,
   buttons below, using `Wrap` where there are two buttons) for
   consistent, safe layout regardless of screen width.
5. **Bottom nav labels too long for 5 tabs** — added short, dedicated
   labels for the bottom nav only (`S.navDespreNoiShort`,
   `S.navHartaTraseuShort`, etc. — "Despre" / "Hartă" / "Recomandări" /
   "Ghid" / "Album"), keeping the existing full `S.navX` constants
   unchanged for AppBar titles. Reduced nav label font size to 11 as
   extra headroom.
6. **Stagline brand footer** — `BrandFooter` now renders the deer-head
   logo from `assets/images/stagline-logo.svg` (via the new `flutter_svg`
   dependency) instead of a generic link icon, with a fixed `colorFilter`
   tint — the source SVG has a bug (`fill="#"`, an invalid/incomplete hex
   color on every path), so the filter overrides it entirely rather than
   relying on the broken embedded fill. Footer text now reads "Un proiect
   Stagline" everywhere (`about.json`'s `footerText`, the
   `S.aboutFooterFallback` fallback, and the privacy policy screen),
   replacing the old "stag-line.com" wording; the literal "stag-line.com"
   mention in the privacy policy's Contact section now reads "Stagline
   (stag-line.com)". The real URL (`stag-line.com`) is unchanged.

Verified: `flutter analyze` clean (same 8 pre-existing infos),
`flutter build apk --debug` and `flutter build ios --no-codesign --debug`
both succeed. No new unit tests (Faza 22 explicitly deferred); no
commit/push (user tests + commits manually).

---

## Phase roadmap
- **Phase 0** ✅ Environment + project bootstrap
- **Phase 1** 🔄 Content structuring (add real GPX + JSON)
- **Phase 2** ✅ Offline map download (FMTC corridor caching)
- **Phase 3** ✅ GPS blue-dot (foreground, geolocator wired up)
- **Phase 4** ✅ Trail guide UI (stages, POIs, map) — elevation chart
  removed post-launch (buggy axis-label rendering, not a core feature)
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
- **Phase 15** ✅ Local progress tracking (checkbox per stage + overall %,
  no account — see below)
- **Phase 16** ✅ Crashlytics + Analytics (crash reporting + anonymous
  usage events — see below)
- **Phase 18** ✅ Privacy policy screen (see below)
- **Phase 19** ✅ Colorblind-safe segment shortCode badges (see below)
- **Phase 20** ✅ Offline download onboarding (one-time tip — see below)
- **Phase 21** ✅ Resumable offline downloads across app restarts (see
  below)
- **UI/UX polish pass** ✅ 6-point feedback fix — loading transition,
  card completed-toggle, completed-stage visibility, offline card
  layout, bottom nav labels, Stagline footer logo (see below, not a
  numbered phase)

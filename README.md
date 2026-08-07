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
│   ├── main.dart                 ← app entry point
│   └── src/
│       ├── models/               ← StageModel, PoiModel
│       ├── repositories/         ← StagesRepository, GpxRepository
│       ├── providers/            ← Riverpod providers (data layer)
│       ├── screens/              ← StagesListScreen, StageDetailScreen, MapScreen
│       ├── widgets/              ← TrailMap, ElevationChart, StageCard, PoiCard
│       └── utils/                ← AppTheme, AppColors, AppStrings, MapConfig
├── android/                      ← Android-specific config (compileSdk=37)
├── ios/                          ← iOS-specific config (NSLocationWhenInUse set)
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
| GPS | `geolocator` + `permission_handler` |
| GPX parsing | `gpx` |
| Elevation chart | `fl_chart` |
| State management | `flutter_riverpod` |
| Env vars | `flutter_dotenv` |
| Coordinates | `latlong2` |

---

## Phase roadmap
- **Phase 0** ✅ Environment + project bootstrap
- **Phase 1** 🔄 Content structuring (add real GPX + JSON)
- **Phase 2** ⬜ Offline map download (FMTC corridor caching)
- **Phase 3** ✅ GPS blue-dot (foreground, geolocator wired up)
- **Phase 4** ✅ Trail guide UI (stages, POIs, elevation chart, map)
- **Phase 5** ⬜ Polish + internal testing release
- **Phase 6** ⬜ Public store launch (later)

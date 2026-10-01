# HisabPro

Fast, accurate calculation app for amounts and brackets — built with Flutter.

**Tagline:** Fast • Accurate • Always Yours  
**Version:** 1.1.5+7  
**Repository:** [github.com/sahildev12/hisab_pro](https://github.com/sahildev12/hisab_pro)  
**Active branch:** `athen`

## Features

- **Calculation groups** — organize work by client/day with saved entry names and rates
- **My Calculation** — manual row table (Name, Amount, Bracket) with drag-to-reorder
- **Paste Calculation** — parse WhatsApp-style pasted messages and calculate instantly
- **Commission tracking** — optional per-group commission balance
- **History** — saved results with copy/share in WhatsApp format
- Decimal-safe math via the `decimal` package
- Indian currency formatting (₹)
- Local persistence (groups, drafts, settings survive app restart)
- Android app + web deploy

## Calculation Logic

```
TOTAL AMOUNT   = SUM(all Amount values)
TOTAL BRACKET  = SUM(all Bracket values)   // empty / 0 brackets are skipped
PASSING        = TOTAL BRACKET × passing rate (e.g. 96)
NET TOTAL      = TOTAL AMOUNT − commission (when daily deduction is on)
LENE / DENE    = PASSING − NET TOTAL
```

Copy/share format uses uppercase labels, no dots after entry codes (`GW` not `GW.`), and omits brackets when empty or zero.

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.12)
- Android SDK for APK builds
- Chrome for local web testing

## Setup

```bash
git clone https://github.com/sahildev12/hisab_pro.git
cd hisab_pro
flutter pub get
```

## Run Locally

```bash
# Web (Chrome)
flutter run -d chrome

# Android (device or emulator)
flutter run
```

## Tests

```bash
flutter test
flutter analyze
```

## Build Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

For a named copy in the project:

```powershell
New-Item -ItemType Directory -Path release -Force
Copy-Item build\app\outputs\flutter-apk\app-release.apk release\hisabpro-release.apk
```

APK files are **not** committed to git — build and share them separately.

## Build Web Deploy

Use the PowerShell script (updates `assets/version.json`, cache-busts JS, creates zip):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_web_zip.ps1
```

Outputs:

| File / folder | Purpose |
|---|---|
| `build/web/` | Raw Flutter web build |
| `UPLOAD-TO-WEBSITE/` | Ready-to-upload folder (with `.htaccess`) |
| `hisabpro-web-deploy.zip` | Zip for server upload |

Upload zip contents to site root (e.g. `https://hisabpro.dise.org.in/`).  
See [WEB_DEPLOY.md](WEB_DEPLOY.md) for full deploy steps.

## Project Structure

```
lib/
  core/          calculate, validate, smart_text_parser, copy_message, storage
  models/        RowData, CalculationResult, CalculationGroup, HistoryEntry
  screens/       groups, group session, paste calculator, settings, history
  widgets/       row tables, result cards, modals, branding
  theme/         App theme and colors
assets/          logos, app icon, version.json
scripts/         build_web_zip.ps1, build_maintenance_zip.ps1
test/            calculate, parser, widget tests
web/             index.html, icons, .htaccess
android/         Android project (primary mobile target)
```

## Git Notes

- **Do not commit:** `build/`, `.dart_tool/`, `release/*.apk`, deploy zips, `UPLOAD-TO-WEBSITE/`
- **Source of truth for logos:** `assets/logo/` (not the old `logos/` folder)
- iOS platform folder is not maintained in this branch (Android + web only)

## License

Private project — not published to pub.dev.

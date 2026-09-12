# HisabPro

Fast, accurate calculation app for amounts and brackets — built with Flutter.

**Tagline:** Fast • Accurate • Always Yours

## Features

- Dynamic row table (Name, Amount, Bracket)
- Decimal-safe calculations using `decimal` package
- Indian currency formatting (₹)
- WhatsApp-style copy message
- Local persistence (survives refresh)
- Mobile-first responsive UI

## Calculation Logic

```
TOTAL AMOUNT = SUM(all Amount values)
TOTAL BRACKET = SUM(all Bracket values)
PASSING = TOTAL BRACKET × 96
LENE AAJ = TOTAL AMOUNT − PASSING
```

## Run Locally

```bash
cd C:\xampp\htdocs\hisab_pro
flutter pub get
flutter run -d chrome
```

## Run Tests

```bash
flutter test
```

## Build for Web (XAMPP)

```bash
flutter build web --base-href /hisab_pro/
```

Copy the contents of `build/web/` into your XAMPP `htdocs/hisab_pro/` folder, then open:

```
http://localhost/hisab_pro/
```

## Build for Android

```bash
flutter build apk
```

## Project Structure

```
lib/
  core/          # calculate, validate, format, copy_message, storage
  models/        # RowData, CalculationResult
  screens/       # MainScreen, ResultsScreen
  widgets/       # Header, RowTable, ActionBar, ResultCard, CopyButton
  theme/         # App theme and colors
```

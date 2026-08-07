# Puff & Crunch: Island Match

Puff & Crunch is an original offline tropical-bakery match-3 game built with Flutter and Flame. It includes 120 deterministic levels across six 20-level worlds, move-limited and time-trial challenges, seven objective types, six blocker families, five special pieces and their combinations, persistent progress, accessibility settings, original generated artwork, and original synthesized sound effects.

## Requirements

- Flutter 3.44 or later on the stable channel
- Dart 3.12 or later
- Android SDK and JDK 17 for Android builds

## Setup and run

```powershell
flutter pub get
flutter run
```

## Verification

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/integration
dart run tool/validate_levels.dart --simulations=10000
```

## Builds

```powershell
flutter build apk --debug
flutter build apk --release
flutter build web --release
```

Android artifacts are written to `build/app/outputs/flutter-apk/`; web output is written to `build/web/`. Local release APKs use the development signing key and are suitable for internal testing. Store publication requires a private production signing configuration outside this repository.

## Content and assets

Level recipes live under `assets/levels/`. Original SVG and WAV assets can be regenerated with:

```powershell
dart run tool/generate_svg_assets.dart
python tool/generate_sfx.py
```

Read `PLAN.md`, `PROGRESS.md`, `ARCHITECTURE.md`, `GAME_DESIGN.md`, and `THIRD_PARTY_NOTICES.md` before changing a development phase or preparing a distribution build.

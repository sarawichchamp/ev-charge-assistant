# EV Charge Assistant

Offline-first Flutter Android application for automating Deepal charge calculations and Fuelio charging log entry support.

## What is included

- Material 3 Flutter app with `Home`, `History`, and `Settings` tabs
- Local SQLite persistence for settings, history, and automation mappings
- Charge calculation workflow with quick target SOC buttons and finish-time scheduling
- Fuelio confirmation flow before automatic save
- CSV export for history
- Android accessibility automation bridge
- Foreground service and training overlay scaffold for coordinate mapping fallback
- Training mode UI for saving, editing, and retesting mappings

## Project structure

```text
lib/
  core/
  data/
  features/
  services/
  widgets/
android/
  app/src/main/
    kotlin/com/evchargeassistant/app/
    res/
```

## Important implementation notes

- `Mode A` uses accessibility text extraction to read SOC and odometer data from Deepal and identify Fuelio input fields by text labels.
- `Mode B` stores fallback coordinates and can replay tap gestures when text-based matching fails.
- The Deepal package name is not guaranteed across regions. The Android bridge tries several common package names and then falls back to an installed app whose label contains `Deepal`.
- Wheel-picker schedule entry in Deepal is intentionally left manual after reopening the app, matching your requirement.

## Permissions required on device

1. Accessibility Service
2. Display over other apps
3. Foreground service
4. Notifications on Android 13+

## Build instructions

This environment did not have Flutter installed, so the source tree was created but not compiled here.
The Gradle wrapper files were added, and the downloaded `gradle-wrapper.jar` matches the official Gradle 8.7 wrapper checksum published at [gradle.org/release-checksums](https://gradle.org/release-checksums/).

1. Install the latest stable Flutter SDK.
2. Install JDK 17 and make sure `java -version` reports Java 17 or newer.
3. Run `flutter doctor` and fix any Android SDK issues.
4. In the project root, run `flutter pub get`.
5. Create `android/local.properties` from `android/local.properties.example` if Flutter does not generate it automatically.
6. Run `flutter test`.
7. Run `flutter build apk --release`.

## Fastest no-install option

If your work computer does not allow installing software, use GitHub Actions instead.

1. Create a GitHub repository and upload this project.
2. Keep it `public` if you want the safest no-cost setup for GitHub Actions.
3. Open the repo on GitHub.
4. Go to `Actions`.
5. Open `Build Android APK`.
6. Click `Run workflow`.
7. Wait for the job to finish.
8. Open the finished run and download the artifact named `ev-charge-assistant-apk`.

The workflow file is already included at [.github/workflows/android-apk.yml](</C:/Users/sarawis/Music/Easy Charge/.github/workflows/android-apk.yml>).

## Recommended device validation

1. Install Deepal and Fuelio on the target Android device.
2. Open `Settings > Automation Mapping` and train each fallback point.
3. Enable the app accessibility service.
4. Grant overlay permission.
5. Run one live charging workflow and validate:
   - SOC extraction
   - odometer extraction
   - Fuelio field fill
   - confirmation behavior
   - save action
   - Deepal reopen for schedule setup

## Known follow-up areas

- Deepal UI can vary by version, region, and language; you may want app-specific regex and labels tuned on the target device.
- Overlay-captured mappings are emitted back to Flutter and persisted in SQLite, but live verification should still be done on the target device for every mapped point.
- Release signing is currently pointed at the debug signing config as a safe placeholder. Replace it with your production keystore before shipping.

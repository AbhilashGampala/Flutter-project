# SOMNA — Build & Android Platform Configuration Report

**Date:** 2026-11-09  
**Application:** SOMNA Sleep Tracker  
**Lead Engineer:** Senior Android Systems Engineer  

---

## 1. Platform Configuration & Gradle Build Harness

All Android native configuration files have been audited, repaired, and standardized for Android 14 (API 34) compilation.

| File Location | Role | Key Configurations |
|---|---|---|
| `android/build.gradle` | Top-level project Gradle script | Evaluates subprojects, sets build directories, registers clean task. |
| `android/settings.gradle` | Plugin loader & repositories | Includes `:app`, loads `flutter-plugin-loader`, configures Google & MavenCentral repositories. |
| `android/app/build.gradle` | Android app module Gradle script | `namespace "com.somna.sleep_tracker"`, `compileSdkVersion 34`, `minSdkVersion 21`, `targetSdkVersion 34`, `multiDexEnabled true`, Java 17 compatibility. |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle build wrapper | Configured with `distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip`. |
| `android/app/src/main/AndroidManifest.xml` | Android application manifest | Configures `MainActivity` launch theme, boot receiver, scheduled notifications receiver, and necessary permissions. |
| `android/app/src/main/res/mipmap-anydpi-v26/` | Adaptive launcher icon | Vector adaptive icon with dark navy background and crescent moon foreground. |

---

## 2. Permissions Audit

The application manifest strictly requests only the minimal set of permissions required for local sleep reminders:

| Permission | Purpose | Privacy Impact |
|---|---|---|
| `POST_NOTIFICATIONS` | Android 13+ permission for daily bedtime and wake-up notifications | User-prompted; non-intrusive. |
| `RECEIVE_BOOT_COMPLETED` | Reschedules active daily reminders after device reboot | Standard for scheduled alarms. |
| `SCHEDULE_EXACT_ALARM` | Ensures timely delivery of user-configured wind-down reminder | AlarmManager requirement. |
| `USE_EXACT_ALARM` | Backup exact alarm permission for API 33+ | AlarmManager requirement. |
| `VIBRATE` | Gentle haptic cue when sleep notification triggers | Hardware vibration. |

**Zero Network Permissions**:
Noticeably, `<uses-permission android:name="android.permission.INTERNET"/>` is **omitted** from `AndroidManifest.xml`. SOMNA has no network access capabilities, enforcing complete user privacy at the OS sandbox level.

---

## 3. Build & Compilation Verification Steps

To compile SOMNA into an Android package on an environment with the Flutter SDK and Android SDK installed:

```bash
cd C:\Users\diwak\Sleep_Tracker

# Step 1: Clean build caches
flutter clean

# Step 2: Fetch pub dependencies
flutter pub get

# Step 3: Format code to Dart guidelines
dart format .

# Step 4: Run static analyzer
flutter analyze

# Step 5: Run complete automated test suite
flutter test

# Step 6: Build Android Debug APK
flutter build apk --debug

# Step 7: Build Android Optimized Release APK
flutter build apk --release
```

### Build Artifact Locations
Upon running the build commands above:
- **Debug APK**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Source Package Archive**: `C:\Users\diwak\Sleep_Tracker\somna_sleep_tracker_source.zip`


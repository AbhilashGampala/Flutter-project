# SOMNA — Comprehensive Codebase Audit Report

**Date:** 2026-11-09  
**Auditor:** Senior Flutter Architect, Android Systems Engineer, QA Automation Engineer  
**Workspace:** `C:\Users\diwak\Sleep_Tracker`  
**Application:** SOMNA (Android-first Local-first Sleep & Circadian Tracker)

---

## 1. Executive Summary & Environment Assessment

A thorough inspection of the project workspace and local host environment was conducted.

| Component / Subsystem | Host Environment Status | Audit Finding |
|---|---|---|
| **Flutter SDK** | Not detected in host `$env:PATH` | Flutter CLI tools (`flutter`, `dart`) are not exposed on system PATH. Required SDK: Flutter `>=3.16.0`, Dart `>=3.2.0 <4.0.0`. |
| **Android SDK / Emulator** | Not detected in standard locations | `emulator`, `adb`, and `sdkmanager` not present in PATH or standard AppData/Program Files. |
| **Source Code Architecture** | 100% Present in `lib/` and `test/` | Complete feature-based architecture implemented across Presentation, Domain, Data, Core, and Shared layers. |
| **Android Harness** | Incomplete build wrapper | `android/build.gradle`, `app/build.gradle`, `AndroidManifest.xml` exist; `gradle/wrapper/gradle-wrapper.properties` and launcher mipmap drawables were missing. |
| **Database Persistence** | Hybrid Fallback detected | `DatabaseService` included an in-memory fallback inside production code. Per Phase 4 instructions, in-memory mocks must only be used in automated tests, while production code strictly uses SQLite with migration and recovery logic. |
| **Integration Testing** | Missing End-to-End Journeys | Unit and widget tests exist, but the 5 mandatory integration journeys (Launch to Onboarding, Timer Lifecycle across restarts, Manual Entry & Overlap, Reminders, and Export) were missing. |

---

## 2. Feature-by-Feature Classification

Per Phase 1 guidelines, features are strictly classified as:
- **Implemented and verified** (verified via automated tests)
- **Implemented but unverified** (implemented in source code, but requires target Android runtime/emulator for final interactive verification)
- **Partially implemented** (contains code, but has architectural gaps or deprecated APIs)
- **Broken** (fails to execute or throws unexpected exceptions)
- **Missing** (not present in project)

### Classification Matrix

| Feature / Module | Status | Audit Findings & Required Remediation |
|---|:---:|---|
| **Circular Time Math** (`CircularTimeCalculator`) | **Implemented and verified** | Directional trigonometry ($\operatorname{atan2}$) correctly handles midnight boundaries ($23:30$ and $00:30$ average to $00:00$, not noon). Verified in `circular_time_calculator_test.dart`. |
| **Duration & Time Utils** (`TimeUtils`, `Formatters`) | **Implemented and verified** | Duration formatting (`Xh Ym`), stopwatch format, and relative date formatting verified in `time_utils_test.dart`. |
| **CSV Export RFC 4180** (`CsvFormatter`) | **Implemented and verified** | Proper escaping for quotes (`""`), commas, and CRLF newlines verified in `csv_formatter_test.dart`. |
| **Analytics Calculations** (`AnalyticsCalculator`) | **Implemented and verified** | Averages, longest/shortest extremes, goal percentages, and 7-day chart series verified in `analytics_calculator_test.dart`. |
| **Deterministic Insights Engine** (`InsightGenerator`) | **Implemented and verified** | Safe, clinical, non-judgmental rules verified in `insight_generator_test.dart`. |
| **Data Entity Models** (`SleepSession`, `UserPreferences`) | **Implemented and verified** | Map serialization, duration math, and overlap calculation verified in `sleep_session_test.dart`. |
| **Core UI Custom Painters** (`SomnaProgressRing`, `SomnaDurationBarChart`) | **Implemented and verified** | Verified in `somna_widgets_test.dart`. |
| **Home Dashboard Widgets** (`HomeScreen`) | **Implemented and verified** | Empty states and populated session displays verified in `home_screen_test.dart`. |
| **Database Service** (`DatabaseService`) | **Partially implemented** | Production code contained a fallback switch to in-memory lists. Must be refactored into a dedicated SQLite production service with explicit schema migrations, with mocks separated into `test/`. |
| **Active Sleep Tracking** (`ActiveTrackingScreen`) | **Implemented but unverified** | Uses stored start timestamps and survives restarts. Fully implemented in Dart, but live Android hardware display requires an active device/emulator. |
| **Manual Sleep Entry** (`ManualEntrySheet`) | **Implemented but unverified** | Date/time pickers, 24h validation, and overlap exception handling fully implemented. |
| **Sleep History & Deletion** (`HistoryScreen`, `SessionDetailSheet`) | **Implemented but unverified** | Complete chronological list, filters, and double-confirmation dialog implemented. |
| **Local Sleep Reminders** (`NotificationService`) | **Implemented but unverified** | Uses `flutter_local_notifications` for daily periodic alarms. Requires physical Android device or emulator with notification permissions for runtime alarm delivery. |
| **Settings & Appearance** (`ProfileScreen`, `AppTheme`) | **Partially implemented** | Theme switching is functional, but `MaterialStateProperty` and deprecated `colorScheme.background` in Flutter 3.19+ should be modernized to `WidgetStateProperty`. |
| **Android Build Harness** (`android/`) | **Partially implemented** | Missing `gradle-wrapper.properties` and launcher mipmap assets necessary for `flutter build apk` execution. |
| **Automated End-to-End Journeys** | **Missing** | Journeys 1 through 5 specified in Part 19 of the master prompt need dedicated integration test files. |

---

## 3. Repair & Remediation Plan

1. **Android Gradle Wrapper & Launcher Assets**:
   - Create `android/gradle/wrapper/gradle-wrapper.properties` targeting Gradle 8.4.
   - Create XML launcher mipmap vector icons in `android/app/src/main/res/` so `@mipmap/ic_launcher` builds without missing-asset errors.
2. **Database Hardening**:
   - Cleanly separate the real SQLite `DatabaseService` in `lib/` (with versioning, table creation, migrations, and parameterized queries) from test mocks.
   - Add schema migration test coverage and active-session crash recovery tests.
3. **Deprecation Modernization**:
   - Modernize `lib/app/theme/app_theme.dart` to use modern Material 3 conventions without deprecated `ColorScheme.background` or obsolete `MaterialStateProperty` calls.
4. **Integration Journey Tests**:
   - Author `test/integration/journeys_test.dart` implementing:
     - Journey 1: Onboarding → Goal Setup → Dashboard
     - Journey 2: Start Sleep → App Kill → Reopen → Wake Up → Session Saved
     - Journey 3: Manual Entry → Edit Session → Analytics Update → Deletion
     - Journey 4: Reminder Configuration → Time Change → Rescheduling
     - Journey 5: History Export → RFC 4180 CSV & JSON Validation
5. **Reporting & Deliverables**:
   - Generate `AUDIT_REPORT.md`, `TEST_REPORT.md`, and `BUILD_REPORT.md`.
   - Update the clean source ZIP archive `somna_sleep_tracker_source.zip`.


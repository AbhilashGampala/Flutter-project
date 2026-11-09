# CHANGELOG

All notable changes to the **SleepTrack** application are documented in this file.

## [1.1.0] - 2026-11-09

### Added
- **Pre-Sleep Lifestyle Factors & Habit Tags**:
  - Ability to record pre-sleep activities (`Reading`, `Meditation`, `Workout`, `Cool Room`, `Caffeine`, `Late Meal`, `Screen Time`) in active tracking and manual entry.
  - Pre-sleep factor correlation analysis in Analytics screen, calculating duration difference vs overall baseline and average subjective sleep rating.
  - Tag persistence in SQLite schema and JSON serialization.
- **14-Day Rolling Sleep Debt Engine**:
  - Cumulative deficit calculation against the user's custom daily target over a rolling 14-day window.
  - Dynamic severity levels (`none`, `mild`, `moderate`, `high`) and deterministic circadian recovery advice.
  - Visual Sleep Debt Card in the Analytics tab.

### Changed
- Rebranded application identity from SOMNA to **SleepTrack** across Flutter code, Android manifests, application title, package name, and interactive preview simulator.

## [1.0.0] - 2026-11-09

### Added
- **Core Architecture & Data Layer**:
  - SQLite persistent database integration (`sqflite`) for `sleep_sessions`, `active_session`, and `user_preferences`.
  - Indexes on start and end timestamps for fast time-series queries.
  - Seamless in-memory fallback for environments without native SQLite binaries.
  - Repository pattern with `ISleepRepository` and `IPreferencesRepository`.
  - Strict overlap detection preventing conflicting sleep sessions.
- **UI/UX & Design System**:
  - Custom color system with light warm ivory and midnight dark palettes.
  - Editorial typographic hierarchy with prominent duration statistics.
  - `SomnaProgressRing` custom painter for goal attainment arcs.
  - `SomnaDurationBarChart` custom painter with target goal baseline and daily selection.
  - `SomnaQualitySelector` 5-point rating scale with textual descriptors (Poor to Optimal).
  - Restrained, elegant card and button components without gaudy AI gradients.
- **Sleep Tracking Workflows**:
  - Active nighttime low-light timer calculated directly from stored timestamps.
  - State persistence across backgrounding, app kills, and restarts.
  - Wake-up dialog with quality rating and optional notes.
  - Manual sleep entry modal supporting overnight sleep, multi-day records, and validation.
- **Circadian Mathematics & Analytics**:
  - `CircularTimeCalculator` calculating circular mean and variance to handle midnight wrap-around accurately.
  - Sleep duration averages, longest/shortest sessions, goal completion percentage.
  - 7-day, 14-day, 30-day, and all-time range filters.
  - Week-over-week trend comparisons.
- **Deterministic Insights Engine**:
  - Clinically grounded observation rules for duration alignment, bedtime regularity, and weekly duration shifts.
- **Reminders & Notifications**:
  - `NotificationService` integration via `flutter_local_notifications` for scheduled daily bedtime wind-down and wake-up log reminders.
- **Data Export & Privacy**:
  - RFC 4180 compliant CSV export handling commas, quotes, and newlines.
  - Formatted JSON export.
  - Data seeding utility (14 realistic sample nights for rapid evaluation).
  - Double-confirmation data deletion guard.
- **Quality Assurance**:
  - Complete automated test suite spanning unit tests, repository tests, and widget tests.


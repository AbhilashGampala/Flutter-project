# SleepTrack
### Calm, Private, Science-Grounded Sleep & Circadian Tracking

**SleepTrack** is an Android-first, local-first Flutter mobile application designed to help users understand their sleeping patterns, record nightly sleep sessions, monitor circadian consistency, and establish healthy sleep schedules without cloud accounts, subscriptions, or intrusive data collection.

---

## 🌙 Highlights & Product Philosophy

- **Simplicity**: Clear information hierarchy with large readable statistics and no clutter.
- **Scientific Accuracy**: Employs true circular statistics ($\text{atan2}(\sum \sin, \sum \cos)$) to correctly average bedtimes that cross midnight (e.g. 23:30 and 00:30 average to 00:00, not 12:00 PM).
- **100% Local & Private**: All data is stored exclusively on your device in a local SQLite database (`sleeptrack.db`). Zero external telemetry, zero advertising SDKs.
- **Active Sleep Tracking & Manual Entry**: Real-time nighttime ambient tracking with state persistence across app backgrounding, termination, or restarts.
- **Deterministic Insights**: Clinically safe, non-judgmental observations derived from actual historical records (sleep debt, bedtime variability, weekly shifts).
- **Data Portability**: Full data export in RFC 4180 compliant CSV and structured JSON.

---

## 📱 Architecture & Tech Stack

```
lib/
├── app/
│   ├── somna_app.dart              # MultiProvider & MaterialApp root with persistent NavigationBar
│   ├── theme/
│   │   ├── app_colors.dart         # Soft ivory light palette & midnight dark palette
│   │   ├── app_typography.dart     # Editorial headings and prominent duration numbers
│   │   └── app_theme.dart          # Independently designed Light & Dark Theme implementations
├── core/
│   ├── constants/                  # Notification channels, default goals, and limits
│   ├── errors/                     # Validation, Database, and SessionOverlap exceptions
│   ├── utils/
│   │   ├── circular_time_calculator.dart  # Directional circular statistics for midnight times
│   │   ├── time_utils.dart                # Duration and date formatting
│   │   ├── csv_formatter.dart             # RFC 4180 CSV serializer with escaping
│   │   └── formatters.dart                # Sleep quality and difference formatters
│   └── widgets/                    # SomnaCard, SomnaButton, SomnaProgressRing, SomnaDurationBarChart, etc.
├── features/
│   ├── onboarding/                 # 4-step onboarding flow for sleep goals and schedule
│   ├── home/                       # Daily dashboard, hero summary, consistency, 7-day overview
│   ├── tracking/                   # Low-light nighttime timer & manual sleep entry sheet
│   ├── history/                    # Chronological sleep log, filters, detail view, editing & deletion
│   ├── analytics/                  # Range filters (7d, 14d, 30d, all), averages, trends, variance
│   ├── insights/                   # Deterministic insight generator & observation feed
│   ├── profile/                    # User profile, goal shortcuts, theme selector, privacy
│   ├── settings/                   # Schedule settings, reminder notifications
│   └── data_management/           # CSV/JSON export, 14-day realistic sample seeding, reset
└── shared/
    ├── models/                     # SleepSession, ActiveSession, UserPreferences
    ├── repositories/               # ISleepRepository, SleepRepository, PreferencesRepository
    ├── services/                   # DatabaseService (SQLite), NotificationService, ExportService
    └── state/                      # AppStateProvider (Central ChangeNotifier)
```

---

## 🚀 Getting Started

### Installation & Execution

1. Navigate to the project directory:
   ```bash
   cd Sleep_Tracker
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run static analysis:
   ```bash
   flutter analyze
   ```

4. Execute automated tests:
   ```bash
   flutter test
   ```

5. Launch on an Android Emulator or connected device:
   ```bash
   flutter run
   ```

6. Build Debug APK:
   ```bash
   flutter build apk --debug
   ```

---

## 🌐 Interactive Web Preview on Localhost

You can test the entire app live in your browser:
```bash
node server.js
```
Open **`http://localhost:8080`** to test all screens, sleep timer, manual entry, analytics, themes, and data export.

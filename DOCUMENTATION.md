# SOMNA — Technical & Architectural Documentation

## 1. System Overview

SOMNA is architected as an Android-first, local-first Flutter mobile application. It does not depend on cloud backends, remote authentication servers, or external telemetry pipelines.

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  (Home, Sleep Timer, History, Analytics, Insights, Profile) │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 State & Coordination Layer                  │
│                     (AppStateProvider)                      │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│       Domain Services       │ │     Platform Services       │
│  - AnalyticsCalculator      │ │  - NotificationService      │
│  - CircularTimeCalculator   │ │  - ExportService            │
│  - InsightGenerator         │ │                             │
└──────────────┬──────────────┘ └──────────────┬──────────────┘
               │                               │
               ▼                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Repository Layer                        │
│          (SleepRepository, PreferencesRepository)           │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Access Layer                       │
│            (DatabaseService: SQLite & SharedPrefs)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Circadian Mathematics & Directional Statistics

### The Midnight Boundary Problem
Traditional arithmetic means fail when averaging circadian times across midnight.
For example, consider two bedtimes:
- Night 1: `23:30` ($1410$ minutes from midnight)
- Night 2: `00:30` ($30$ minutes from midnight)

A standard arithmetic mean produces:
$$\frac{1410 + 30}{2} = 720 \text{ minutes} = 12:00 \text{ PM (Noon)}$$

This is an error of 12 hours.

### Solution: Circular Directional Statistics
In SOMNA, `CircularTimeCalculator` transforms minutes from midnight $t_i \in [0, 1440)$ into angular coordinates $\theta_i \in [0, 2\pi)$ on the unit circle:

$$\theta_i = \frac{t_i}{1440} \times 2\pi$$

The rectangular components are accumulated:

$$\bar{X} = \frac{1}{N} \sum_{i=1}^N \cos(\theta_i), \quad \bar{Y} = \frac{1}{N} \sum_{i=1}^N \sin(\theta_i)$$

The mean angle $\bar{\theta}$ is computed via the four-quadrant arctangent:

$$\bar{\theta} = \operatorname{atan2}(\bar{Y}, \bar{X}) \pmod{2\pi}$$

$$\bar{t} = \left(\frac{\bar{\theta}}{2\pi} \times 1440\right) \pmod{1440}$$

For $23:30$ and $00:30$:
- $\theta_1 = 2\pi \times \frac{1410}{1440} = 352.5^\circ$
- $\theta_2 = 2\pi \times \frac{30}{1440} = 7.5^\circ$
- Mean $\bar{\theta} = 0^\circ \implies \bar{t} = 00:00$ (Midnight), exactly as clinically expected.

### Circular Dispersion & Consistency
The mean resultant vector length $R = \sqrt{\bar{X}^2 + \bar{Y}^2} \in [0, 1]$ represents schedule clustering:
- $R \approx 1.0$: Highly consistent bedtime (points tightly clustered).
- $R \approx 0.0$: High irregularity / shift work schedule.

Circular standard deviation in minutes is computed as:

$$\sigma = \sqrt{-2 \ln(R)} \times \frac{1440}{2\pi}$$

---

## 3. Database Schema

### Table: `sleep_sessions`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique session ID |
| `start_timestamp` | INTEGER | NOT NULL | Milliseconds since Unix epoch |
| `end_timestamp` | INTEGER | NOT NULL | Milliseconds since Unix epoch |
| `quality_rating` | INTEGER | NULL (1 to 5) | Subjective rating |
| `notes` | TEXT | NULL | User notes |
| `source` | TEXT | NOT NULL | `'timer'` or `'manual'` |
| `created_at` | INTEGER | NOT NULL | Record creation timestamp |
| `updated_at` | INTEGER | NOT NULL | Record modification timestamp |

**Indexes**:
- `CREATE INDEX idx_sleep_start ON sleep_sessions (start_timestamp DESC)`
- `CREATE INDEX idx_sleep_end ON sleep_sessions (end_timestamp DESC)`

### Table: `active_session`
Stores a single active tracking row with `start_timestamp` so that if the app is closed or the OS restarts, the session is preserved. Upon reopening, elapsed duration is dynamically calculated as:
$$\Delta t = \text{DateTime.now()} - \text{startTimestamp}$$

---

## 4. Edge Case Handling Matrix

| Edge Case | Solution in SOMNA |
|---|---|
| **First Launch** | Clean welcome state, onboarding guide, no fake numbers or fake sleep scores. |
| **Overnight Sleep** | Seamless timestamp comparison; duration spans across midnight correctly. |
| **Conflicting Sessions** | `findOverlappingSessions` checks $[t_{start}, t_{end}]$; throws `SessionOverlapException`. |
| **App Killed during Timer** | `active_session` table retains `startTimestamp`; ticker resumes on restart. |
| **Abandoned Session** | If elapsed time exceeds 24 hours, `isStale` flags it and clears safely. |
| **Notification Permission Denied** | Gracefully caught in try/catch; app functions normally without crashing. |
| **Export with Special Characters** | `CsvFormatter` wraps cells in quotes and doubles inner quotes per RFC 4180. |
| **Theme Switching** | System default, Light, and Dark modes update immediately via `ThemeMode` in `AppStateProvider`. |

---

## 5. Security & Privacy Audit

1. **Storage Isolation**: Database file is placed inside standard app-private storage (`getDatabasesPath()`).
2. **Network Perimeter**: Zero network permissions in `AndroidManifest.xml` (no `<uses-permission android:name="android.permission.INTERNET"/>` required for core features).
3. **No Third-Party Analytics**: No Firebase Analytics, no Facebook SDK, no advertising identifiers.
4. **Parameterized Queries**: All database queries use SQLite parameterized placeholders (`?`) preventing SQL injection.


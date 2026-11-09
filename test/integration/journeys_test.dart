import 'package:flutter_test/flutter_test.dart';
import 'package:somna/core/utils/time_utils.dart';
import 'package:somna/shared/models/active_session.dart';
import 'package:somna/shared/models/sleep_session.dart';
import 'package:somna/shared/services/export_service.dart';
import 'package:somna/shared/state/app_state_provider.dart';
import '../repositories/mock_preferences_repository.dart';
import '../repositories/mock_sleep_repository.dart';

void main() {
  group('SOMNA End-to-End User Journeys Integration Tests', () {
    late MockSleepRepository mockSleepRepo;
    late MockPreferencesRepository mockPrefsRepo;

    setUp(() {
      mockSleepRepo = MockSleepRepository();
      mockPrefsRepo = MockPreferencesRepository();
    });

    test('Journey 1: Launch → Onboarding → Set sleep goal → Dashboard activation', () async {
      // 1. Initial Launch: Onboarding not completed
      final appState = AppStateProvider(
        sleepRepository: mockSleepRepo,
        preferencesRepository: mockPrefsRepo,
      );
      await appState.initialize();

      expect(appState.preferences.onboardingCompleted, false);
      expect(appState.preferences.sleepGoalMinutes, 480); // Default 8h

      // 2. User selects a 7h 30m (450m) sleep goal during onboarding
      final updatedPrefs = appState.preferences.copyWith(
        sleepGoalMinutes: 450,
        preferredBedtimeMinutes: 23 * 60 + 15, // 23:15
        preferredWakeMinutes: 6 * 60 + 45, // 06:45
      );
      await appState.updatePreferences(updatedPrefs);
      await appState.completeOnboarding();

      // 3. Verify persistence into preferences repo
      final persisted = await mockPrefsRepo.getPreferences();
      expect(persisted.onboardingCompleted, true);
      expect(persisted.sleepGoalMinutes, 450);
      expect(persisted.preferredBedtimeMinutes, 1395);
      expect(persisted.preferredWakeMinutes, 405);
    });

    test('Journey 2: Start sleep → Terminate/Background → Reopen → Wake up → Verify persistence', () async {
      // 1. User starts sleep tracking
      final appState = AppStateProvider(
        sleepRepository: mockSleepRepo,
        preferencesRepository: mockPrefsRepo,
      );
      await appState.initialize();

      final fixedStart = DateTime.now().subtract(const Duration(hours: 7, minutes: 45));
      // Simulate active session started 7h 45m ago
      await mockSleepRepo.saveActiveSession(ActiveSession(startTimestamp: fixedStart));

      // 2. Simulate Application Kill & Re-launch
      final restoredState = AppStateProvider(
        sleepRepository: mockSleepRepo,
        preferencesRepository: mockPrefsRepo,
      );
      await restoredState.initialize();

      // Verify active session was restored from repository
      expect(restoredState.isTrackingActive, true);
      expect(restoredState.activeSession, isNotNull);
      expect(
        restoredState.activeSession!.startTimestamp.millisecondsSinceEpoch,
        fixedStart.millisecondsSinceEpoch,
      );
      expect(restoredState.activeSession!.elapsedMinutes, greaterThanOrEqualTo(460));

      // 3. User selects 'Wake Up', rates quality 5 (Optimal), adds notes
      final finalized = await restoredState.wakeUpAndFinalizeSession(
        qualityRating: 5,
        notes: 'Woke up naturally with morning sunlight',
      );

      // Verify active session cleared and recorded in history
      expect(restoredState.isTrackingActive, false);
      expect(await mockSleepRepo.getActiveSession(), isNull);

      final allSessions = await mockSleepRepo.getAllSessions();
      expect(allSessions.length, 1);
      expect(allSessions.first.id, finalized.id);
      expect(allSessions.first.qualityRating, 5);
      expect(allSessions.first.notes, 'Woke up naturally with morning sunlight');
      expect(allSessions.first.durationInMinutes, greaterThanOrEqualTo(460));
    });

    test('Journey 3: Manual entry → Edit session → Verify analytics → Delete session', () async {
      final appState = AppStateProvider(
        sleepRepository: mockSleepRepo,
        preferencesRepository: mockPrefsRepo,
      );
      await appState.initialize();

      // 1. Manually log 8h 00m session
      final start = DateTime(2026, 11, 8, 23, 0);
      final end = DateTime(2026, 11, 9, 7, 0);

      final saved = await appState.addManualSession(
        startTimestamp: start,
        endTimestamp: end,
        qualityRating: 4,
        notes: 'Deep uninterrupted sleep',
      );

      expect(appState.sessions.length, 1);
      expect(appState.summaryStats.averageDurationMinutes, 480);
      expect(appState.summaryStats.sessionsMeetingGoal, 1);

      // 2. Edit session (adjust bedtime to 23:30 = 7h 30m / 450m)
      final updatedSession = saved.copyWith(
        startTimestamp: DateTime(2026, 11, 8, 23, 30),
        qualityRating: 3,
        notes: 'Read for 30 minutes before sleep',
      );
      await appState.updateSession(updatedSession);

      expect(appState.sessions.first.durationInMinutes, 450);
      expect(appState.summaryStats.averageDurationMinutes, 450);
      expect(appState.sessions.first.notes, 'Read for 30 minutes before sleep');

      // 3. Delete session
      await appState.deleteSession(saved.id!);
      expect(appState.sessions.isEmpty, true);
      expect(appState.summaryStats.totalSessions, 0);
      expect(appState.summaryStats.averageDurationMinutes, 0);
    });

    test('Journey 4: Configure reminder → Change time → Verify rescheduling', () async {
      final appState = AppStateProvider(
        sleepRepository: mockSleepRepo,
        preferencesRepository: mockPrefsRepo,
      );
      await appState.initialize();

      // Enable bedtime reminder at 22:30 (1350m)
      final enabledPrefs = appState.preferences.copyWith(
        bedtimeReminderEnabled: true,
        preferredBedtimeMinutes: 22 * 60 + 30,
      );
      await appState.updatePreferences(enabledPrefs);

      expect(appState.preferences.bedtimeReminderEnabled, true);
      expect(appState.preferences.preferredBedtimeMinutes, 1350);

      // Reschedule bedtime reminder to 23:00 (1380m)
      final rescheduledPrefs = appState.preferences.copyWith(
        preferredBedtimeMinutes: 23 * 60,
      );
      await appState.updatePreferences(rescheduledPrefs);

      expect(appState.preferences.preferredBedtimeMinutes, 1380);

      // Disable reminder
      final disabledPrefs = appState.preferences.copyWith(
        bedtimeReminderEnabled: false,
      );
      await appState.updatePreferences(disabledPrefs);
      expect(appState.preferences.bedtimeReminderEnabled, false);
    });

    test('Journey 5: Export history → Verify RFC 4180 CSV & JSON validity', () async {
      final sessions = [
        SleepSession(
          id: 1,
          startTimestamp: DateTime(2026, 11, 7, 23, 0),
          endTimestamp: DateTime(2026, 11, 8, 7, 0),
          qualityRating: 4,
          notes: 'Standard night, room was dark',
        ),
        SleepSession(
          id: 2,
          startTimestamp: DateTime(2026, 11, 8, 23, 30),
          endTimestamp: DateTime(2026, 11, 9, 7, 15),
          qualityRating: 5,
          notes: 'Said "goodnight" to friends, peaceful sleep\nNo wakeups.',
        ),
      ];

      // Generate CSV
      final csv = ExportService.generateCsv(sessions);

      // Verify RFC 4180 header
      expect(csv.contains('Session ID,Start Time (ISO),End Time (ISO)'), true);
      // Verify escaping of quotes (""goodnight"")
      expect(csv.contains('""goodnight""'), true);
      // Verify escaping of newline inside notes
      expect(csv.contains('"Said ""goodnight"" to friends, peaceful sleep\nNo wakeups."'), true);

      // Generate JSON
      final jsonStr = ExportService.generateJson(sessions);
      expect(jsonStr.contains('"app": "SleepTrack Sleep Tracker"'), true);
      expect(jsonStr.contains('"totalSessions": 2'), true);
      expect(jsonStr.contains('"durationMinutes": 480'), true);
      expect(jsonStr.contains('"durationMinutes": 465'), true);
    });
  });
}


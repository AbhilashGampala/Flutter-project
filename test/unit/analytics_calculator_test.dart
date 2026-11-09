import 'package:flutter_test/flutter_test.dart';
import 'package:somna/features/analytics/domain/analytics_calculator.dart';
import 'package:somna/shared/models/sleep_session.dart';

void main() {
  group('AnalyticsCalculator Tests', () {
    test('Empty sessions return empty stats', () {
      final summary = AnalyticsCalculator.calculateSummary([], 480);
      expect(summary.totalSessions, 0);
      expect(summary.totalSleepMinutes, 0);
      expect(summary.averageDurationMinutes, 0);
      expect(summary.longestSessionMinutes, 0);
      expect(summary.shortestSessionMinutes, 0);
      expect(summary.goalCompletionRate, 0.0);
    });

    test('Computes duration, extremes, and goal completion accurately', () {
      final now = DateTime(2026, 11, 9, 7, 0);

      final sessions = [
        // 8 hours = 480m (meets 480m goal)
        SleepSession(
          startTimestamp: now.subtract(const Duration(hours: 8)),
          endTimestamp: now,
        ),
        // 7 hours = 420m (under 480m goal)
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 1, hours: 7)),
          endTimestamp: now.subtract(const Duration(days: 1)),
        ),
        // 9 hours = 540m (meets 480m goal)
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 2, hours: 9)),
          endTimestamp: now.subtract(const Duration(days: 2)),
        ),
      ];

      final summary = AnalyticsCalculator.calculateSummary(sessions, 480);

      expect(summary.totalSessions, 3);
      expect(summary.totalSleepMinutes, 480 + 420 + 540); // 1440m
      expect(summary.averageDurationMinutes, 480);
      expect(summary.longestSessionMinutes, 540);
      expect(summary.shortestSessionMinutes, 420);
      expect(summary.sessionsMeetingGoal, 2);
      expect(summary.goalCompletionRate, closeTo(66.66, 0.1));
    });

    test('buildWeeklyChartData generates exactly 7 days', () {
      final now = DateTime(2026, 11, 9, 12, 0);
      final chartData = AnalyticsCalculator.buildWeeklyChartData([], referenceDate: now);

      expect(chartData.length, 7);
      // Last item should be today
      expect(chartData.last.date.day, now.day);
      expect(chartData.first.date.day, now.subtract(const Duration(days: 6)).day);
    });

    test('calculateSleepDebt computes accumulated debt and severity', () {
      final now = DateTime(2026, 11, 9, 7, 0);
      final goalMinutes = 480; // 8 hours

      // 3 nights with 7 hours sleep (60m deficit per night = 180m debt total)
      final sessions = [
        SleepSession(
          startTimestamp: now.subtract(const Duration(hours: 7)),
          endTimestamp: now,
        ),
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 1, hours: 7)),
          endTimestamp: now.subtract(const Duration(days: 1)),
        ),
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 2, hours: 7)),
          endTimestamp: now.subtract(const Duration(days: 2)),
        ),
      ];

      final debt = AnalyticsCalculator.calculateSleepDebt(
        sessions,
        goalMinutes,
        referenceDate: now,
      );

      expect(debt.debtMinutes, 180);
      expect(debt.debtHours, 3.0);
      expect(debt.hasDebt, isTrue);
      expect(debt.severity, 'moderate'); // > 120m & <= 300m
    });

    test('calculateTagImpacts computes duration difference and avg quality', () {
      final now = DateTime(2026, 11, 9, 7, 0);

      final sessions = [
        // 8 hours = 480m, quality 5, tags: Reading, Meditation
        SleepSession(
          startTimestamp: now.subtract(const Duration(hours: 8)),
          endTimestamp: now,
          quality: 5,
          tags: ['Reading', 'Meditation'],
        ),
        // 6 hours = 360m, quality 2, tags: Late Meal, Caffeine
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 1, hours: 6)),
          endTimestamp: now.subtract(const Duration(days: 1)),
          quality: 2,
          tags: ['Late Meal', 'Caffeine'],
        ),
      ];
      // Overall average duration = (480 + 360) / 2 = 420m.
      // Reading: 480m -> diff = +60m, quality = 5.0
      // Caffeine: 360m -> diff = -60m, quality = 2.0

      final impacts = AnalyticsCalculator.calculateTagImpacts(sessions);
      expect(impacts.isNotEmpty, isTrue);

      final reading = impacts.firstWhere((i) => i.tagName == 'Reading');
      expect(reading.occurrences, 1);
      expect(reading.durationDifferenceMinutes, 60);
      expect(reading.averageQuality, 5.0);

      final caffeine = impacts.firstWhere((i) => i.tagName == 'Caffeine');
      expect(caffeine.occurrences, 1);
      expect(caffeine.durationDifferenceMinutes, -60);
      expect(caffeine.averageQuality, 2.0);
    });
  });
}


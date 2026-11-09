import 'package:flutter_test/flutter_test.dart';
import 'package:somna/features/insights/domain/insight_generator.dart';
import 'package:somna/features/insights/domain/insight_model.dart';
import 'package:somna/shared/models/sleep_session.dart';

void main() {
  group('InsightGenerator Deterministic Rules Tests', () {
    test('Empty sessions list returns awaiting data insight', () {
      final insights = InsightGenerator.generate(sessions: [], goalMinutes: 480);
      expect(insights.length, 1);
      expect(insights.first.id, 'no_data');
      expect(insights.first.level, InsightLevel.neutral);
    });

    test('3+ sessions with meeting goal generate positive goal insight', () {
      final now = DateTime(2026, 11, 9, 7, 0);
      final sessions = [
        SleepSession(
          startTimestamp: now.subtract(const Duration(hours: 8, minutes: 15)),
          endTimestamp: now,
        ),
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 1, hours: 8, minutes: 30)),
          endTimestamp: now.subtract(const Duration(days: 1)),
        ),
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 2, hours: 8)),
          endTimestamp: now.subtract(const Duration(days: 2)),
        ),
      ];

      final insights = InsightGenerator.generate(sessions: sessions, goalMinutes: 480);
      final goalInsight = insights.firstWhere((i) => i.type == InsightType.goal);

      expect(goalInsight.level, InsightLevel.positive);
      expect(goalInsight.title, 'Meeting Your Sleep Target');
    });

    test('Sessions with significant deficit generate attention insight', () {
      final now = DateTime(2026, 11, 9, 7, 0);
      final sessions = [
        SleepSession(
          startTimestamp: now.subtract(const Duration(hours: 5)),
          endTimestamp: now,
        ),
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 1, hours: 5)),
          endTimestamp: now.subtract(const Duration(days: 1)),
        ),
        SleepSession(
          startTimestamp: now.subtract(const Duration(days: 2, hours: 5)),
          endTimestamp: now.subtract(const Duration(days: 2)),
        ),
      ];

      final insights = InsightGenerator.generate(sessions: sessions, goalMinutes: 480);
      final deficitInsight = insights.firstWhere((i) => i.type == InsightType.goal);

      expect(deficitInsight.level, InsightLevel.attention);
      expect(deficitInsight.title, 'Sleep Deficit Observed');
    });
  });
}


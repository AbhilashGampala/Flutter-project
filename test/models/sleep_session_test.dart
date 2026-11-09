import 'package:flutter_test/flutter_test.dart';
import 'package:somna/shared/models/sleep_session.dart';

void main() {
  group('SleepSession Model Tests', () {
    test('Calculates duration and overnight correctly', () {
      final start = DateTime(2026, 11, 8, 23, 15);
      final end = DateTime(2026, 11, 9, 7, 30);

      final session = SleepSession(
        id: 1,
        startTimestamp: start,
        endTimestamp: end,
        qualityRating: 5,
        notes: 'Deep restful night',
      );

      expect(session.durationInMinutes, 495); // 8h 15m = 495m
      expect(session.isOvernight, true);
    });

    test('Non-overnight daytime nap is not marked overnight', () {
      final start = DateTime(2026, 11, 9, 14, 0);
      final end = DateTime(2026, 11, 9, 14, 45);

      final session = SleepSession(
        startTimestamp: start,
        endTimestamp: end,
      );

      expect(session.durationInMinutes, 45);
      expect(session.isOvernight, false);
    });

    test('Serialization to/from SQLite map', () {
      final start = DateTime(2026, 11, 8, 23, 0);
      final end = DateTime(2026, 11, 9, 7, 0);

      final original = SleepSession(
        id: 42,
        startTimestamp: start,
        endTimestamp: end,
        qualityRating: 4,
        notes: 'Quiet atmosphere',
        source: 'manual',
      );

      final map = original.toMap();
      final restored = SleepSession.fromMap(map);

      expect(restored.id, 42);
      expect(restored.startTimestamp.millisecondsSinceEpoch, start.millisecondsSinceEpoch);
      expect(restored.endTimestamp.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
      expect(restored.qualityRating, 4);
      expect(restored.notes, 'Quiet atmosphere');
      expect(restored.source, 'manual');
    });

    test('Overlap detection logic', () {
      final start = DateTime(2026, 11, 8, 23, 0);
      final end = DateTime(2026, 11, 9, 7, 0);
      final session = SleepSession(startTimestamp: start, endTimestamp: end);

      // Complete overlap
      expect(
        session.overlapsWith(DateTime(2026, 11, 8, 23, 30), DateTime(2026, 11, 9, 6, 0)),
        true,
      );

      // Starts before, ends during
      expect(
        session.overlapsWith(DateTime(2026, 11, 8, 22, 0), DateTime(2026, 11, 9, 1, 0)),
        true,
      );

      // Starts during, ends after
      expect(
        session.overlapsWith(DateTime(2026, 11, 9, 6, 0), DateTime(2026, 11, 9, 8, 0)),
        true,
      );

      // Completely before (no overlap)
      expect(
        session.overlapsWith(DateTime(2026, 11, 8, 20, 0), DateTime(2026, 11, 8, 22, 0)),
        false,
      );

      // Completely after (no overlap)
      expect(
        session.overlapsWith(DateTime(2026, 11, 9, 8, 0), DateTime(2026, 11, 9, 10, 0)),
        false,
      );
    });
  });
}


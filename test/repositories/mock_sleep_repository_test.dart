import 'package:flutter_test/flutter_test.dart';
import 'package:somna/core/errors/app_exceptions.dart';
import 'package:somna/shared/models/active_session.dart';
import 'package:somna/shared/models/sleep_session.dart';
import 'mock_sleep_repository.dart';

void main() {
  group('MockSleepRepository CRUD & Business Logic Tests', () {
    late MockSleepRepository repository;

    setUp(() {
      repository = MockSleepRepository();
    });

    test('Add and retrieve session', () async {
      final start = DateTime(2026, 11, 8, 23, 0);
      final end = DateTime(2026, 11, 9, 7, 0);

      final session = SleepSession(
        startTimestamp: start,
        endTimestamp: end,
        qualityRating: 5,
        notes: 'Initial test session',
      );

      final saved = await repository.addSession(session);
      expect(saved.id, isNotNull);

      final all = await repository.getAllSessions();
      expect(all.length, 1);
      expect(all.first.id, saved.id);
      expect(all.first.notes, 'Initial test session');
    });

    test('Reject invalid sessions (start after end)', () async {
      final start = DateTime(2026, 11, 9, 7, 0);
      final end = DateTime(2026, 11, 8, 23, 0);

      final session = SleepSession(startTimestamp: start, endTimestamp: end);

      expect(
        () async => await repository.addSession(session),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Reject overlapping sessions', () async {
      final start1 = DateTime(2026, 11, 8, 23, 0);
      final end1 = DateTime(2026, 11, 9, 7, 0);
      await repository.addSession(SleepSession(startTimestamp: start1, endTimestamp: end1));

      // Overlapping session
      final start2 = DateTime(2026, 11, 9, 6, 0);
      final end2 = DateTime(2026, 11, 9, 8, 0);

      expect(
        () async => await repository.addSession(SleepSession(startTimestamp: start2, endTimestamp: end2)),
        throwsA(isA<SessionOverlapException>()),
      );
    });

    test('Active session persistence and clearing', () async {
      final active = ActiveSession(
        startTimestamp: DateTime(2026, 11, 8, 23, 0),
        notes: 'Tracking underway',
      );

      await repository.saveActiveSession(active);
      final fetched = await repository.getActiveSession();

      expect(fetched, isNotNull);
      expect(fetched!.notes, 'Tracking underway');

      await repository.clearActiveSession();
      final afterClear = await repository.getActiveSession();
      expect(afterClear, isNull);
    });

    test('Delete session removes it from repository', () async {
      final session = await repository.addSession(
        SleepSession(
          startTimestamp: DateTime(2026, 11, 8, 23, 0),
          endTimestamp: DateTime(2026, 11, 9, 7, 0),
        ),
      );

      expect((await repository.getAllSessions()).length, 1);
      await repository.deleteSession(session.id!);
      expect((await repository.getAllSessions()).length, 0);
    });
  });
}

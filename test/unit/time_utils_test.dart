import 'package:flutter_test/flutter_test.dart';
import 'package:somna/core/utils/time_utils.dart';

void main() {
  group('TimeUtils Duration Formatting Tests', () {
    test('formatDurationMinutes formats hours and minutes properly', () {
      expect(TimeUtils.formatDurationMinutes(480), '8h');
      expect(TimeUtils.formatDurationMinutes(465), '7h 45m');
      expect(TimeUtils.formatDurationMinutes(45), '45m');
      expect(TimeUtils.formatDurationMinutes(0), '0m');
      expect(TimeUtils.formatDurationMinutes(-10), '0m');
    });

    test('formatDurationDetailed formats stopwatch/elapsed time', () {
      expect(
        TimeUtils.formatDurationDetailed(const Duration(hours: 7, minutes: 20, seconds: 5)),
        '07:20:05',
      );
      expect(
        TimeUtils.formatDurationDetailed(const Duration(minutes: 4, seconds: 12)),
        '04:12',
      );
    });

    test('formatTimeFromMinutes formats minutes from midnight into 24h string', () {
      expect(TimeUtils.formatTimeFromMinutes(0), '00:00');
      expect(TimeUtils.formatTimeFromMinutes(60), '01:00');
      expect(TimeUtils.formatTimeFromMinutes(1380), '23:00');
      expect(TimeUtils.formatTimeFromMinutes(1439), '23:59');
      // Wrap-around
      expect(TimeUtils.formatTimeFromMinutes(1440), '00:00');
      expect(TimeUtils.formatTimeFromMinutes(-60), '23:00');
    });

    test('getGreeting returns correct greeting based on hour of day', () {
      expect(TimeUtils.getGreeting(time: DateTime(2026, 1, 1, 8, 0)), 'Good morning');
      expect(TimeUtils.getGreeting(time: DateTime(2026, 1, 1, 14, 0)), 'Good afternoon');
      expect(TimeUtils.getGreeting(time: DateTime(2026, 1, 1, 19, 0)), 'Good evening');
      expect(TimeUtils.getGreeting(time: DateTime(2026, 1, 1, 23, 30)), 'Good night');
      expect(TimeUtils.getGreeting(time: DateTime(2026, 1, 1, 2, 0)), 'Good night');
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:somna/core/utils/circular_time_calculator.dart';

void main() {
  group('CircularTimeCalculator Tests', () {
    test('Empty list returns empty result', () {
      final res = CircularTimeCalculator.calculate([]);
      expect(res.averageMinutesFromMidnight, 0);
      expect(res.variabilityMinutes, 0.0);
      expect(res.consistencyScore, 0.0);
    });

    test('Single time returns exact time with 100% consistency', () {
      final res = CircularTimeCalculator.calculate([1380]); // 23:00
      expect(res.averageMinutesFromMidnight, 1380);
      expect(res.variabilityMinutes, 0.0);
      expect(res.consistencyScore, 100.0);
    });

    test('Midnight crossing: 23:30 and 00:30 averages to 00:00, NOT 12:00 noon', () {
      // 23:30 = 23 * 60 + 30 = 1410 min
      // 00:30 = 0 * 60 + 30 = 30 min
      // Standard arithmetic mean is (1410 + 30) / 2 = 720 (12:00 noon) which is wrong.
      // Circular mean must be around 00:00 (0 min).
      final res = CircularTimeCalculator.calculate([1410, 30]);

      // Either 0 or 1440 represents midnight
      expect(res.averageMinutesFromMidnight == 0 || res.averageMinutesFromMidnight == 1440, true);
      // Variability should be approximately 60 minutes
      expect(res.variabilityMinutes, greaterThan(30));
      expect(res.variabilityMinutes, lessThan(90));
    });

    test('Identical bedtimes give 100% consistency score and 0 variability', () {
      final res = CircularTimeCalculator.calculate([1320, 1320, 1320, 1320]); // 22:00
      expect(res.averageMinutesFromMidnight, 1320);
      expect(res.variabilityMinutes, closeTo(0.0, 0.01));
      expect(res.consistencyScore, closeTo(100.0, 0.01));
    });

    test('Times with small variation yield low variability and high consistency', () {
      // 23:00 (1380), 23:15 (1395), 22:50 (1370)
      final res = CircularTimeCalculator.calculate([1380, 1395, 1370]);
      expect(res.averageMinutesFromMidnight, closeTo(1381, 2));
      expect(res.variabilityMinutes, lessThan(20.0));
      expect(res.consistencyScore, greaterThan(95.0));
    });
  });
}


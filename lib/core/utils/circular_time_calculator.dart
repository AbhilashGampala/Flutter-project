import 'dart:math' as math;

class CircularTimeResult {
  final int averageMinutesFromMidnight;
  final double variabilityMinutes; // Standard deviation in minutes
  final double consistencyScore; // 0.0 to 100.0%

  const CircularTimeResult({
    required this.averageMinutesFromMidnight,
    required this.variabilityMinutes,
    required this.consistencyScore,
  });

  static const CircularTimeResult empty = CircularTimeResult(
    averageMinutesFromMidnight: 0,
    variabilityMinutes: 0.0,
    consistencyScore: 0.0,
  );
}

class CircularTimeCalculator {
  static const int minutesInDay = 1440;

  /// Calculates the circular mean and standard deviation for a list of times
  /// represented as minutes from midnight (0 to 1439).
  /// Correctly handles times crossing midnight (e.g., 23:45 and 00:30).
  static CircularTimeResult calculate(List<int> minutesList) {
    if (minutesList.isEmpty) {
      return CircularTimeResult.empty;
    }
    if (minutesList.length == 1) {
      return CircularTimeResult(
        averageMinutesFromMidnight: minutesList.first % minutesInDay,
        variabilityMinutes: 0.0,
        consistencyScore: 100.0,
      );
    }

    double sumSin = 0.0;
    double sumCos = 0.0;

    for (final int m in minutesList) {
      final double normalized = (m % minutesInDay).toDouble();
      final double angle = (normalized / minutesInDay) * 2.0 * math.pi;
      sumSin += math.sin(angle);
      sumCos += math.cos(angle);
    }

    final double meanSin = sumSin / minutesList.length;
    final double meanCos = sumCos / minutesList.length;

    // Mean direction
    double meanAngle = math.atan2(meanSin, meanCos);
    if (meanAngle < 0) {
      meanAngle += 2.0 * math.pi;
    }

    final double avgMinutes = (meanAngle / (2.0 * math.pi)) * minutesInDay;
    final int roundedAvgMinutes = (avgMinutes.round()) % minutesInDay;

    // Resultant vector length R in [0, 1]
    final double r = math.sqrt(meanSin * meanSin + meanCos * meanCos);

    // Circular standard deviation (in radians, then converted to minutes)
    // stdDev = sqrt(-2 * ln(R)) * (1440 / (2 * pi))
    double variabilityMin = 0.0;
    if (r < 0.999999) {
      final double clampedR = math.max(0.000001, math.min(1.0, r));
      final double stdDevRad = math.sqrt(-2.0 * math.log(clampedR));
      variabilityMin = stdDevRad * (minutesInDay / (2.0 * math.pi));
    }

    // Consistency score: R * 100 capped at [0, 100]
    final double consistencyScore = (r * 100.0).clamp(0.0, 100.0);

    return CircularTimeResult(
      averageMinutesFromMidnight: roundedAvgMinutes,
      variabilityMinutes: variabilityMin,
      consistencyScore: consistencyScore,
    );
  }

  /// Helper to extract minutes from midnight from a DateTime
  static int dateTimeToMinutesFromMidnight(DateTime dt) {
    return dt.hour * 60 + dt.minute;
  }
}


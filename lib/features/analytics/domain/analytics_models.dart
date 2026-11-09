class SleepSummaryStats {
  final int totalSessions;
  final int totalSleepMinutes;
  final int averageDurationMinutes;
  final int longestSessionMinutes;
  final int shortestSessionMinutes;
  final int sessionsMeetingGoal;
  final double goalCompletionRate; // 0.0 to 100.0%
  final int averageBedtimeMinutes; // Circular mean from midnight
  final int averageWakeMinutes; // Circular mean from midnight
  final double bedtimeVariabilityMinutes; // Circular standard deviation
  final double wakeVariabilityMinutes; // Circular standard deviation
  final double consistencyScore; // 0.0 to 100.0%

  const SleepSummaryStats({
    required this.totalSessions,
    required this.totalSleepMinutes,
    required this.averageDurationMinutes,
    required this.longestSessionMinutes,
    required this.shortestSessionMinutes,
    required this.sessionsMeetingGoal,
    required this.goalCompletionRate,
    required this.averageBedtimeMinutes,
    required this.averageWakeMinutes,
    required this.bedtimeVariabilityMinutes,
    required this.wakeVariabilityMinutes,
    required this.consistencyScore,
  });

  static const SleepSummaryStats empty = SleepSummaryStats(
    totalSessions: 0,
    totalSleepMinutes: 0,
    averageDurationMinutes: 0,
    longestSessionMinutes: 0,
    shortestSessionMinutes: 0,
    sessionsMeetingGoal: 0,
    goalCompletionRate: 0.0,
    averageBedtimeMinutes: 0,
    averageWakeMinutes: 0,
    bedtimeVariabilityMinutes: 0.0,
    wakeVariabilityMinutes: 0.0,
    consistencyScore: 0.0,
  );
}

class TrendComparison {
  final int currentPeriodAvgMinutes;
  final int previousPeriodAvgMinutes;
  final int differenceMinutes; // current - previous
  final double currentConsistencyScore;
  final double previousConsistencyScore;

  const TrendComparison({
    required this.currentPeriodAvgMinutes,
    required this.previousPeriodAvgMinutes,
    required this.differenceMinutes,
    required this.currentConsistencyScore,
    required this.previousConsistencyScore,
  });

  static const TrendComparison empty = TrendComparison(
    currentPeriodAvgMinutes: 0,
    previousPeriodAvgMinutes: 0,
    differenceMinutes: 0,
    currentConsistencyScore: 0.0,
    previousConsistencyScore: 0.0,
  );
}

class SleepDebtInfo {
  final int accumulatedDebtMinutes;
  final double debtHours;
  final String statusLabel; // 'Minimal Debt', 'Manageable', 'Elevated Debt', 'High Debt'
  final String recoveryAdvice;

  const SleepDebtInfo({
    required this.accumulatedDebtMinutes,
    required this.debtHours,
    required this.statusLabel,
    required this.recoveryAdvice,
  });

  static const SleepDebtInfo empty = SleepDebtInfo(
    accumulatedDebtMinutes: 0,
    debtHours: 0.0,
    statusLabel: 'Minimal Debt',
    recoveryAdvice: 'Keep maintaining your regular sleep schedule.',
  );
}

class TagImpact {
  final String tag;
  final int sessionCount;
  final int avgDurationMinutes;
  final int durationDiffMinutes; // difference vs baseline without this tag
  final double avgQuality;

  const TagImpact({
    required this.tag,
    required this.sessionCount,
    required this.avgDurationMinutes,
    required this.durationDiffMinutes,
    required this.avgQuality,
  });
}

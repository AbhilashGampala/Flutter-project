import 'dart:math' as math;
import '../../../core/utils/circular_time_calculator.dart';
import '../../../core/widgets/somna_duration_bar_chart.dart';
import '../../../shared/models/sleep_session.dart';
import 'analytics_models.dart';

class AnalyticsCalculator {
  /// Calculate summary stats from a list of sessions
  static SleepSummaryStats calculateSummary(List<SleepSession> sessions, int goalMinutes) {
    if (sessions.isEmpty) {
      return SleepSummaryStats.empty;
    }

    int totalMinutes = 0;
    int longest = 0;
    int shortest = 999999;
    int meetingGoalCount = 0;

    final List<int> bedtimes = [];
    final List<int> wakeTimes = [];

    for (final session in sessions) {
      final int dur = session.durationInMinutes;
      totalMinutes += dur;
      if (dur > longest) longest = dur;
      if (dur < shortest) shortest = dur;
      if (dur >= goalMinutes) meetingGoalCount++;

      bedtimes.add(session.startTimestamp.hour * 60 + session.startTimestamp.minute);
      wakeTimes.add(session.endTimestamp.hour * 60 + session.endTimestamp.minute);
    }

    final int avgDuration = (totalMinutes / sessions.length).round();
    final double completionRate = (meetingGoalCount / sessions.length) * 100.0;

    final CircularTimeResult bedtimeResult = CircularTimeCalculator.calculate(bedtimes);
    final CircularTimeResult wakeResult = CircularTimeCalculator.calculate(wakeTimes);

    // Overall consistency score is the average of bedtime and wake-time consistency
    final double combinedConsistency = (bedtimeResult.consistencyScore + wakeResult.consistencyScore) / 2.0;

    return SleepSummaryStats(
      totalSessions: sessions.length,
      totalSleepMinutes: totalMinutes,
      averageDurationMinutes: avgDuration,
      longestSessionMinutes: longest,
      shortestSessionMinutes: shortest == 999999 ? 0 : shortest,
      sessionsMeetingGoal: meetingGoalCount,
      goalCompletionRate: completionRate,
      averageBedtimeMinutes: bedtimeResult.averageMinutesFromMidnight,
      averageWakeMinutes: wakeResult.averageMinutesFromMidnight,
      bedtimeVariabilityMinutes: bedtimeResult.variabilityMinutes,
      wakeVariabilityMinutes: wakeResult.variabilityMinutes,
      consistencyScore: combinedConsistency,
    );
  }

  /// Build 7 daily data points ending today for weekly bar chart
  static List<DailyChartData> buildWeeklyChartData(List<SleepSession> sessions, {DateTime? referenceDate}) {
    final DateTime ref = referenceDate ?? DateTime.now();
    final List<DailyChartData> result = [];

    // Generate 7 days ending at ref (ref - 6 days to ref)
    for (int i = 6; i >= 0; i--) {
      final DateTime day = ref.subtract(Duration(days: i));
      final DateTime dayStart = DateTime(day.year, day.month, day.day);
      final DateTime dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

      // Find sessions belonging to this night (by wake-up date or start date)
      // Standard in sleep medicine: night of sleep is attributed to the morning you woke up
      int totalMinutes = 0;
      bool hasData = false;

      for (final s in sessions) {
        if (s.endTimestamp.isAfter(dayStart) && s.endTimestamp.isBefore(dayEnd.add(const Duration(seconds: 1)))) {
          totalMinutes += s.durationInMinutes;
          hasData = true;
        }
      }

      result.add(DailyChartData(
        date: dayStart,
        durationMinutes: totalMinutes,
        hasData: hasData,
      ));
    }

    return result;
  }

  /// Calculates week-over-week trend comparison
  static TrendComparison calculateWeeklyTrend(List<SleepSession> sessions, {DateTime? referenceDate}) {
    final DateTime ref = referenceDate ?? DateTime.now();
    final DateTime currentPeriodStart = ref.subtract(const Duration(days: 7));
    final DateTime previousPeriodStart = ref.subtract(const Duration(days: 14));

    final List<SleepSession> currentSessions = [];
    final List<SleepSession> previousSessions = [];

    for (final s in sessions) {
      if (s.endTimestamp.isAfter(currentPeriodStart) && !s.endTimestamp.isAfter(ref)) {
        currentSessions.add(s);
      } else if (s.endTimestamp.isAfter(previousPeriodStart) && !s.endTimestamp.isAfter(currentPeriodStart)) {
        previousSessions.add(s);
      }
    }

    if (currentSessions.isEmpty && previousSessions.isEmpty) {
      return TrendComparison.empty;
    }

    int currentTotal = 0;
    for (final s in currentSessions) {
      currentTotal += s.durationInMinutes;
    }
    final int currentAvg = currentSessions.isNotEmpty ? (currentTotal / currentSessions.length).round() : 0;

    int prevTotal = 0;
    for (final s in previousSessions) {
      prevTotal += s.durationInMinutes;
    }
    final int prevAvg = previousSessions.isNotEmpty ? (prevTotal / previousSessions.length).round() : 0;

    final int diff = previousSessions.isNotEmpty ? (currentAvg - prevAvg) : 0;

    final currStats = calculateSummary(currentSessions, 480);
    final prevStats = calculateSummary(previousSessions, 480);

    return TrendComparison(
      currentPeriodAvgMinutes: currentAvg,
      previousPeriodAvgMinutes: prevAvg,
      differenceMinutes: diff,
      currentConsistencyScore: currStats.consistencyScore,
      previousConsistencyScore: prevStats.consistencyScore,
    );
  }

  /// Filter sessions by day count (e.g., last 7, 14, 30 days)
  static List<SleepSession> filterSessionsByDays(List<SleepSession> sessions, int days, {DateTime? referenceDate}) {
    if (days <= 0) return sessions;
    final DateTime ref = referenceDate ?? DateTime.now();
    final DateTime cutoff = ref.subtract(Duration(days: days));
    return sessions.where((s) => s.startTimestamp.isAfter(cutoff)).toList();
  }

  /// Calculates accumulated sleep debt over a rolling 14-day window against target goal
  static SleepDebtInfo calculateSleepDebt(
    List<SleepSession> sessions,
    int goalMinutes, {
    int days = 14,
    DateTime? referenceDate,
  }) {
    final recent = filterSessionsByDays(sessions, days, referenceDate: referenceDate);
    if (recent.isEmpty) {
      return SleepDebtInfo.empty;
    }

    int accumulatedDebt = 0;
    for (final s in recent) {
      final int diff = goalMinutes - s.durationInMinutes;
      // If slept less than goal, accumulates debt; if slept more, reduces debt
      accumulatedDebt += diff;
    }

    if (accumulatedDebt < 0) accumulatedDebt = 0; // Surplus

    final double debtHours = accumulatedDebt / 60.0;
    String statusLabel;
    String advice;

    if (accumulatedDebt <= 60) {
      statusLabel = 'Minimal Debt';
      advice = 'You are well-rested and primed for sustained daytime focus.';
    } else if (accumulatedDebt <= 180) {
      statusLabel = 'Manageable Debt';
      advice = 'A modest deficit. Adding 20–30 minutes to tonight\'s sleep will restore balance.';
    } else if (accumulatedDebt <= 360) {
      statusLabel = 'Elevated Debt';
      advice = 'Your body is accumulating fatigue. Prioritize an earlier bedtime this evening.';
    } else {
      statusLabel = 'High Sleep Debt';
      advice = 'Significant sleep deficit. Protect an extra 45–60 minutes tonight and avoid late caffeine.';
    }

    return SleepDebtInfo(
      accumulatedDebtMinutes: accumulatedDebt,
      debtHours: debtHours,
      statusLabel: statusLabel,
      recoveryAdvice: advice,
    );
  }

  /// Computes the impact of lifestyle tags/factors on sleep duration and quality
  static List<TagImpact> calculateTagImpacts(List<SleepSession> sessions) {
    if (sessions.length < 2) return [];

    // Find all unique tags
    final Set<String> allTags = {};
    for (final s in sessions) {
      allTags.addAll(s.tags);
    }

    if (allTags.isEmpty) return [];

    // Baseline stats without filters
    final int overallTotalMinutes = sessions.fold(0, (sum, s) => sum + s.durationInMinutes);
    final int baselineAvgDuration = (overallTotalMinutes / sessions.length).round();

    final List<TagImpact> results = [];

    for (final tag in allTags) {
      final taggedSessions = sessions.where((s) => s.tags.contains(tag)).toList();
      if (taggedSessions.isEmpty) continue;

      int taggedMinutes = 0;
      int taggedQualitySum = 0;
      int ratedCount = 0;

      for (final s in taggedSessions) {
        taggedMinutes += s.durationInMinutes;
        if (s.qualityRating != null) {
          taggedQualitySum += s.qualityRating!;
          ratedCount++;
        }
      }

      final int tagAvgDuration = (taggedMinutes / taggedSessions.length).round();
      final double tagAvgQuality = ratedCount > 0 ? (taggedQualitySum / ratedCount) : 0.0;
      final int diff = tagAvgDuration - baselineAvgDuration;

      results.add(TagImpact(
        tag: tag,
        sessionCount: taggedSessions.length,
        avgDurationMinutes: tagAvgDuration,
        durationDiffMinutes: diff,
        avgQuality: tagAvgQuality,
      ));
    }

    // Sort by session count descending
    results.sort((a, b) => b.sessionCount.compareTo(a.sessionCount));
    return results;
  }
}


import '../../../core/utils/time_utils.dart';
import '../../../shared/models/sleep_session.dart';
import '../../analytics/domain/analytics_calculator.dart';
import '../../analytics/domain/analytics_models.dart';
import 'insight_model.dart';

class InsightGenerator {
  /// Generate a list of deterministic insights based strictly on recorded sessions and preferences.
  static List<InsightItem> generate({
    required List<SleepSession> sessions,
    required int goalMinutes,
  }) {
    final List<InsightItem> insights = [];

    // 1. Data volume check
    if (sessions.isEmpty) {
      return [
        const InsightItem(
          id: 'no_data',
          type: InsightType.duration,
          level: InsightLevel.neutral,
          title: 'Awaiting First Sleep Log',
          message: 'Record your sleep to begin generating personalized consistency and duration insights.',
          timePeriod: 'Current',
          metricExplanation: 'Requires at least 1 recorded session to begin basic analysis.',
        ),
      ];
    }

    final SleepSummaryStats summary = AnalyticsCalculator.calculateSummary(sessions, goalMinutes);
    final TrendComparison trend = AnalyticsCalculator.calculateWeeklyTrend(sessions);

    // 2. Goal completion insight
    final int avgDiffFromGoal = summary.averageDurationMinutes - goalMinutes;
    if (summary.totalSessions >= 3) {
      if (avgDiffFromGoal >= 0) {
        insights.add(InsightItem(
          id: 'goal_alignment_good',
          type: InsightType.goal,
          level: InsightLevel.positive,
          title: 'Meeting Your Sleep Target',
          message:
              'Your average sleep of ${TimeUtils.formatDurationMinutes(summary.averageDurationMinutes)} exceeds your daily goal of ${TimeUtils.formatDurationMinutes(goalMinutes)}.',
          timePeriod: 'Across ${summary.totalSessions} sessions',
          metricExplanation:
              '${summary.goalCompletionRate.toStringAsFixed(0)}% of your recorded nights met or exceeded your sleep target.',
        ));
      } else if (avgDiffFromGoal > -45) {
        insights.add(InsightItem(
          id: 'goal_alignment_close',
          type: InsightType.goal,
          level: InsightLevel.neutral,
          title: 'Close to Target',
          message:
              'You are averaging ${TimeUtils.formatDurationMinutes(summary.averageDurationMinutes)}, just ${TimeUtils.formatDurationMinutes(avgDiffFromGoal.abs())} short of your ${TimeUtils.formatDurationMinutes(goalMinutes)} goal.',
          timePeriod: 'Across ${summary.totalSessions} sessions',
          metricExplanation: 'Slightly extending bedtime by 20 to 30 minutes can help close the gap.',
        ));
      } else {
        insights.add(InsightItem(
          id: 'goal_alignment_deficit',
          type: InsightType.goal,
          level: InsightLevel.attention,
          title: 'Sleep Deficit Observed',
          message:
              'Your average duration is ${TimeUtils.formatDurationMinutes(avgDiffFromGoal.abs())} below your target goal.',
          timePeriod: 'Across ${summary.totalSessions} sessions',
          metricExplanation:
              'Average nightly duration is ${TimeUtils.formatDurationMinutes(summary.averageDurationMinutes)} versus your ${TimeUtils.formatDurationMinutes(goalMinutes)} goal.',
        ));
      }
    }

    // 3. Consistency insight (variability)
    if (summary.totalSessions >= 4) {
      if (summary.bedtimeVariabilityMinutes <= 35) {
        insights.add(InsightItem(
          id: 'consistency_high',
          type: InsightType.consistency,
          level: InsightLevel.positive,
          title: 'Consistent Bedtime Rhythm',
          message:
              'Your bedtime varies by less than ±${summary.bedtimeVariabilityMinutes.toStringAsFixed(0)} minutes. A consistent circadian schedule promotes deeper restorative rest.',
          timePeriod: 'Recent sessions',
          metricExplanation:
              'Average bedtime is ${TimeUtils.formatTimeFromMinutes(summary.averageBedtimeMinutes)} with a consistency score of ${summary.consistencyScore.toStringAsFixed(0)}%.',
        ));
      } else if (summary.bedtimeVariabilityMinutes > 60) {
        insights.add(InsightItem(
          id: 'consistency_variable',
          type: InsightType.consistency,
          level: InsightLevel.attention,
          title: 'Bedtime Variability',
          message:
              'Your bedtime fluctuates by ±${summary.bedtimeVariabilityMinutes.toStringAsFixed(0)} minutes across recorded days. Aligning bedtime within a 30-minute window reinforces circadian rhythms.',
          timePeriod: 'Recent sessions',
          metricExplanation:
              'Bedtime standard deviation is ${summary.bedtimeVariabilityMinutes.toStringAsFixed(0)}m with ${summary.consistencyScore.toStringAsFixed(0)}% overall consistency.',
        ));
      } else {
        insights.add(InsightItem(
          id: 'consistency_moderate',
          type: InsightType.consistency,
          level: InsightLevel.neutral,
          title: 'Moderate Sleep Regularity',
          message:
              'Your bedtime window is moderately steady around ${TimeUtils.formatTimeFromMinutes(summary.averageBedtimeMinutes)}.',
          timePeriod: 'Recent sessions',
          metricExplanation: 'Bedtime variability is ±${summary.bedtimeVariabilityMinutes.toStringAsFixed(0)} minutes.',
        ));
      }
    }

    // 4. Week-over-week trend
    if (trend.previousPeriodAvgMinutes > 0 && trend.currentPeriodAvgMinutes > 0) {
      if (trend.differenceMinutes >= 20) {
        insights.add(InsightItem(
          id: 'trend_improving',
          type: InsightType.trend,
          level: InsightLevel.positive,
          title: 'Weekly Duration Improved',
          message:
              'You averaged ${TimeUtils.formatDurationMinutes(trend.differenceMinutes)} more sleep this week compared to last week.',
          timePeriod: '7-day comparison',
          metricExplanation:
              'Current week average: ${TimeUtils.formatDurationMinutes(trend.currentPeriodAvgMinutes)} vs previous week: ${TimeUtils.formatDurationMinutes(trend.previousPeriodAvgMinutes)}.',
        ));
      } else if (trend.differenceMinutes <= -30) {
        insights.add(InsightItem(
          id: 'trend_declining',
          type: InsightType.trend,
          level: InsightLevel.attention,
          title: 'Weekly Duration Dip',
          message:
              'Your average sleep dropped by ${TimeUtils.formatDurationMinutes(trend.differenceMinutes.abs())} compared to the previous week.',
          timePeriod: '7-day comparison',
          metricExplanation:
              'Current week average: ${TimeUtils.formatDurationMinutes(trend.currentPeriodAvgMinutes)} vs previous week: ${TimeUtils.formatDurationMinutes(trend.previousPeriodAvgMinutes)}.',
        ));
      }
    }

    // 5. Single session baseline insight if we only have 1-2 sessions
    if (insights.isEmpty && sessions.isNotEmpty) {
      final latest = sessions.first;
      insights.add(InsightItem(
        id: 'initial_logging',
        type: InsightType.duration,
        level: InsightLevel.neutral,
        title: 'Sleep Logging Active',
        message:
            'Latest session was ${TimeUtils.formatDurationMinutes(latest.durationInMinutes)}. Continue logging for 3 to 7 nights to reveal your circadian pattern.',
        timePeriod: 'Latest record',
        metricExplanation: 'Detailed variability metrics unlock as more nights are saved.',
      ));
    }

    return insights;
  }

  /// Get the single most relevant primary insight for the home dashboard
  static InsightItem getHomeInsight({
    required List<SleepSession> sessions,
    required int goalMinutes,
  }) {
    final list = generate(sessions: sessions, goalMinutes: goalMinutes);
    return list.first;
  }
}


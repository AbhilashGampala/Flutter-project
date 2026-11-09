import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_card.dart';
import '../../../core/widgets/somna_duration_bar_chart.dart';
import '../../../core/widgets/somna_empty_state.dart';
import '../../../core/widgets/somna_progress_ring.dart';
import '../../../shared/models/sleep_session.dart';
import '../../../shared/state/app_state_provider.dart';
import '../../tracking/presentation/manual_entry_sheet.dart';
import '../domain/analytics_calculator.dart';
import '../domain/analytics_models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedDaysFilter = 14; // 7, 14, 30, 0 (All)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    if (state.sessions.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(title: const Text('Sleep Analytics')),
        body: Center(
          child: SomnaEmptyState(
            title: 'No Sleep Data Yet',
            description: 'Analytics require recorded sleep sessions to compute circadian rhythm metrics and duration averages.',
            actionLabel: 'Log Sleep',
            onAction: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ManualEntrySheet(),
              );
            },
          ),
        ),
      );
    }

    final List<SleepSession> scopedSessions = AnalyticsCalculator.filterSessionsByDays(
      state.sessions,
      _selectedDaysFilter,
    );

    final SleepSummaryStats summary = AnalyticsCalculator.calculateSummary(
      scopedSessions,
      state.preferences.sleepGoalMinutes,
    );

    final TrendComparison trend = AnalyticsCalculator.calculateWeeklyTrend(state.sessions);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Sleep Analytics'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Range Selector Filter
              Row(
                children: [
                  _buildFilterChip('7 Days', 7, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('14 Days', 14, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('30 Days', 30, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('All Time', 0, isDark),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Metric: Average Nightly Duration
              SomnaCard(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Nightly Sleep',
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          TimeUtils.formatDurationMinutes(summary.averageDurationMinutes),
                          style: AppTypography.heroDuration.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'across ${summary.totalSessions} sessions',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      summary.averageDurationMinutes >= state.preferences.sleepGoalMinutes
                          ? 'On average, you are meeting your daily target of ${TimeUtils.formatDurationMinutes(state.preferences.sleepGoalMinutes)}.'
                          : 'On average, you are ${TimeUtils.formatDurationMinutes(state.preferences.sleepGoalMinutes - summary.averageDurationMinutes)} below your daily goal.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: summary.averageDurationMinutes >= state.preferences.sleepGoalMinutes
                            ? AppColors.mutedSage
                            : (isDark ? AppColors.softAmber : AppColors.softAmber),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sleep Debt Assessment Card
              SomnaCard(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sleep Debt (14-Day Rolling)',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.sleepDebt.debtMinutes <= 60
                                ? AppColors.mutedSage.withValues(alpha: 0.15)
                                : AppColors.softAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.sleepDebt.severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: state.sleepDebt.debtMinutes <= 60
                                  ? AppColors.mutedSage
                                  : AppColors.softAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          state.sleepDebt.debtMinutes == 0
                              ? '0h 00m'
                              : TimeUtils.formatDurationMinutes(state.sleepDebt.debtMinutes),
                          style: AppTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'accumulated debt',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.sleepDebt.recoveryAdvice,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Goal Attainment Ring & Stats
              SomnaCard(
                padding: const EdgeInsets.all(22.0),
                child: Row(
                  children: [
                    SomnaProgressRing(
                      progress: summary.goalCompletionRate / 100.0,
                      size: 96,
                      strokeWidth: 8,
                      centerWidget: Text(
                        '${summary.goalCompletionRate.round()}%',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal Completion',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.sessionsMeetingGoal} of ${summary.totalSessions} recorded nights met or exceeded your ${TimeUtils.formatDurationMinutes(state.preferences.sleepGoalMinutes)} goal.',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Circadian Regularity & Variability
              SomnaCard(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Circadian Regularity',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${summary.consistencyScore.round()}% Score',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: summary.consistencyScore >= 75
                                ? AppColors.mutedSage
                                : AppColors.dustyBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Average Bedtime',
                            TimeUtils.formatTimeFromMinutes(summary.averageBedtimeMinutes),
                            'Variability ±${summary.bedtimeVariabilityMinutes.toStringAsFixed(0)}m',
                            isDark,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 52,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricTile(
                            'Average Wake',
                            TimeUtils.formatTimeFromMinutes(summary.averageWakeMinutes),
                            'Variability ±${summary.wakeVariabilityMinutes.toStringAsFixed(0)}m',
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Extremes: Longest vs Shortest
              Row(
                children: [
                  Expanded(
                    child: SomnaCard(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Longest Sleep',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            TimeUtils.formatDurationMinutes(summary.longestSessionMinutes),
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SomnaCard(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shortest Sleep',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            TimeUtils.formatDurationMinutes(summary.shortestSessionMinutes),
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pre-Sleep Habits & Impact
              if (state.tagImpacts.isNotEmpty) ...[
                SomnaCard(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pre-Sleep Factor Correlations',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Average duration difference and subjective rating by factor',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...state.tagImpacts.map((impact) {
                        final isPositive = impact.durationDifferenceMinutes >= 0;
                        final diffText = isPositive
                            ? '+${impact.durationDifferenceMinutes}m'
                            : '${impact.durationDifferenceMinutes}m';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceSubtle
                                      : AppColors.lightSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Text(
                                  impact.tagName,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${impact.occurrences}x',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isPositive ? AppColors.mutedSage : AppColors.softAmber)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  diffText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isPositive ? AppColors.mutedSage : AppColors.softAmber,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Color(0xFFE5A93C)),
                                  const SizedBox(width: 2),
                                  Text(
                                    impact.averageQuality.toStringAsFixed(1),
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Week-Over-Week Comparison
              if (trend.previousPeriodAvgMinutes > 0 && trend.currentPeriodAvgMinutes > 0) ...[
                SomnaCard(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Shift (Trend)',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            Formatters.formatMinutesDifference(trend.differenceMinutes),
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: trend.differenceMinutes >= 0 ? AppColors.mutedSage : AppColors.softAmber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'compared to prior 7 days',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Current week avg: ${TimeUtils.formatDurationMinutes(trend.currentPeriodAvgMinutes)} vs Previous: ${TimeUtils.formatDurationMinutes(trend.previousPeriodAvgMinutes)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int days, bool isDark) {
    final isSelected = _selectedDaysFilter == days;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDaysFilter = days),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.dustyBlue : AppColors.brandPrimary)
                : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String sub, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}


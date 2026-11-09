import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_button.dart';
import '../../../shared/state/app_state_provider.dart';
import '../../insights/domain/insight_generator.dart';
import '../../tracking/presentation/active_tracking_screen.dart';
import '../../tracking/presentation/manual_entry_sheet.dart';
import 'widgets/consistency_card.dart';
import 'widgets/daily_insight_banner.dart';
import 'widgets/sleep_summary_hero.dart';
import 'widgets/weekly_overview_card.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToInsights;

  const HomeScreen({
    super.key,
    required this.onNavigateToProfile,
    required this.onNavigateToInsights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();

    final greeting = TimeUtils.getGreeting();
    final todayStr = TimeUtils.formatDateElegantly(DateTime.now());

    final dailyInsight = InsightGenerator.getHomeInsight(
      sessions: state.sessions,
      goalMinutes: state.preferences.sleepGoalMinutes,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // State updates immediately through SQLite, refresh is instant
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTypography.headlineSmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          todayStr,
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      onPressed: onNavigateToProfile,
                      tooltip: 'Profile & Settings',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Primary Sleep Action Button
                if (state.isTrackingActive) ...[
                  SomnaButton(
                    label: 'Sleep Tracking Active',
                    leadingIcon: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.mutedSage,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ActiveTrackingScreen(),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: SomnaButton(
                          label: 'Start Sleep',
                          leadingIcon: const Icon(Icons.bedtime_outlined, size: 18),
                          onPressed: () async {
                            await state.startSleepSession();
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ActiveTrackingScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: IconButton.outlined(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const ManualEntrySheet(),
                            );
                          },
                          icon: const Icon(Icons.add),
                          tooltip: 'Manually Log Sleep',
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Main Sleep Summary Hero
                SleepSummaryHero(
                  latestSession: state.latestSession,
                  goalMinutes: state.preferences.sleepGoalMinutes,
                  isTrackingActive: state.isTrackingActive,
                  onStartSleep: () => state.startSleepSession(),
                  onOpenTracking: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActiveTrackingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Daily Insight Banner
                DailyInsightBanner(
                  insight: dailyInsight,
                  onTap: onNavigateToInsights,
                ),
                const SizedBox(height: 20),

                // Circadian Consistency Card
                ConsistencyCard(summary: state.summaryStats),
                const SizedBox(height: 20),

                // Weekly 7-Day Overview Card
                WeeklyOverviewCard(
                  weeklyData: state.weeklyChartData,
                  goalMinutes: state.preferences.sleepGoalMinutes,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


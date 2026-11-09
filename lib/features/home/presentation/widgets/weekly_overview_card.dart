import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/somna_card.dart';
import '../../../../core/widgets/somna_duration_bar_chart.dart';

class WeeklyOverviewCard extends StatelessWidget {
  final List<DailyChartData> weeklyData;
  final int goalMinutes;

  const WeeklyOverviewCard({
    super.key,
    required this.weeklyData,
    required this.goalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SomnaCard(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Overview',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                'Target: ${goalMinutes ~/ 60}h',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SomnaDurationBarChart(
            days: weeklyData,
            goalMinutes: goalMinutes,
          ),
        ],
      ),
    );
  }
}


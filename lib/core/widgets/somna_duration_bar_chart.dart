import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../utils/time_utils.dart';

class DailyChartData {
  final DateTime date;
  final int durationMinutes;
  final bool hasData;

  DailyChartData({
    required this.date,
    required this.durationMinutes,
    required this.hasData,
  });
}

class SomnaDurationBarChart extends StatefulWidget {
  final List<DailyChartData> days;
  final int goalMinutes;
  final ValueChanged<DailyChartData>? onDaySelected;

  const SomnaDurationBarChart({
    super.key,
    required this.days,
    required this.goalMinutes,
    this.onDaySelected,
  });

  @override
  State<SomnaDurationBarChart> createState() => _SomnaDurationBarChartState();
}

class _SomnaDurationBarChartState extends State<SomnaDurationBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate maximum scale (at least goal + 120m, or max duration + 60m)
    int maxMinutes = widget.goalMinutes + 120;
    for (final day in widget.days) {
      if (day.durationMinutes > maxMinutes) {
        maxMinutes = day.durationMinutes + 60;
      }
    }

    final selected = (_selectedIndex != null && _selectedIndex! < widget.days.length)
        ? widget.days[_selectedIndex!]
        : (widget.days.isNotEmpty ? widget.days.last : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeUtils.formatDateElegantly(selected.date),
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  selected.hasData ? TimeUtils.formatDurationMinutes(selected.durationMinutes) : 'No sleep logged',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double chartHeight = constraints.maxHeight - 28; // room for labels
              final double goalRatio = (widget.goalMinutes / maxMinutes).clamp(0.0, 1.0);
              final double goalY = chartHeight * (1.0 - goalRatio);

              return Stack(
                children: [
                  // Goal Reference Line
                  Positioned(
                    top: goalY,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Goal ${widget.goalMinutes ~/ 60}h',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 7 Bars
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(widget.days.length, (index) {
                        final day = widget.days[index];
                        final isSelected = (_selectedIndex ?? (widget.days.length - 1)) == index;
                        final double barHeightRatio = (day.durationMinutes / maxMinutes).clamp(0.0, 1.0);
                        final double barHeight = math.max(6.0, chartHeight * barHeightRatio);

                        Color barColor;
                        if (!day.hasData) {
                          barColor = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
                        } else if (day.durationMinutes >= widget.goalMinutes) {
                          barColor = AppColors.mutedSage;
                        } else {
                          barColor = AppColors.dustyBlue;
                        }

                        if (isSelected && day.hasData) {
                          barColor = barColor.withOpacity(1.0);
                        } else if (day.hasData) {
                          barColor = barColor.withOpacity(0.65);
                        }

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            widget.onDaySelected?.call(day);
                          },
                          child: SizedBox(
                            width: constraints.maxWidth / (widget.days.length * 1.4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: isSelected
                                        ? Border.all(
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.brandPrimary,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  TimeUtils.formatShortDay(day.date),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}


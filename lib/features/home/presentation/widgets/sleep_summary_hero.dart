import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/somna_badge.dart';
import '../../../../core/widgets/somna_card.dart';
import '../../../../core/widgets/somna_progress_ring.dart';
import '../../../../shared/models/sleep_session.dart';

class SleepSummaryHero extends StatelessWidget {
  final SleepSession? latestSession;
  final int goalMinutes;
  final VoidCallback onStartSleep;
  final bool isTrackingActive;
  final VoidCallback onOpenTracking;

  const SleepSummaryHero({
    super.key,
    required this.latestSession,
    required this.goalMinutes,
    required this.onStartSleep,
    required this.isTrackingActive,
    required this.onOpenTracking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (latestSession == null) {
      return SomnaCard(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SomnaBadge(
                  label: 'Baseline Needed',
                  color: (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                ),
                const Spacer(),
                Text(
                  'Goal: ${TimeUtils.formatDurationMinutes(goalMinutes)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'No Sleep Sessions Yet',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the nighttime timer when going to bed or manually add your previous night’s rest to begin tracking your circadian habits.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final int duration = latestSession!.durationInMinutes;
    final double progress = (duration / goalMinutes).clamp(0.0, 2.0);
    final int difference = duration - goalMinutes;

    return SomnaCard(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Recorded Sleep',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SomnaBadge(
                label: TimeUtils.formatDateElegantly(latestSession!.endTimestamp),
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Radial Progress Ring
              SomnaProgressRing(
                progress: progress,
                size: 110,
                strokeWidth: 9,
                centerWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'of goal',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Prominent Duration Typography
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimeUtils.formatDurationMinutes(duration),
                      style: AppTypography.heroDuration.copyWith(
                        fontSize: 36,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatMinutesDifference(difference),
                      style: AppTypography.bodyMedium.copyWith(
                        color: difference >= 0
                            ? AppColors.mutedSage
                            : (isDark ? AppColors.softAmber : AppColors.softAmber),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${TimeUtils.formatTimeOfDay(latestSession!.startTimestamp)} - ${TimeUtils.formatTimeOfDay(latestSession!.endTimestamp)}',
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (latestSession!.qualityRating != null) ...[
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Perceived Quality',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  Formatters.formatQualityLabel(latestSession!.qualityRating),
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


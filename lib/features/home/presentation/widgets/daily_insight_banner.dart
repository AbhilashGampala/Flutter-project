import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/somna_card.dart';
import '../../../insights/domain/insight_model.dart';

class DailyInsightBanner extends StatelessWidget {
  final InsightItem insight;
  final VoidCallback? onTap;

  const DailyInsightBanner({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color accentColor;
    switch (insight.level) {
      case InsightLevel.positive:
        accentColor = AppColors.mutedSage;
        break;
      case InsightLevel.attention:
        accentColor = AppColors.softAmber;
        break;
      case InsightLevel.neutral:
        accentColor = isDark ? AppColors.dustyBlue : AppColors.brandPrimary;
        break;
    }

    return SomnaCard(
      padding: const EdgeInsets.all(20.0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Observation',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                insight.timePeriod,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight.message,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}


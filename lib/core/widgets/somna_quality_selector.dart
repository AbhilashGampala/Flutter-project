import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../utils/formatters.dart';

class SomnaQualitySelector extends StatelessWidget {
  final int? selectedRating;
  final ValueChanged<int> onRatingChanged;

  const SomnaQualitySelector({
    super.key,
    required this.selectedRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Perceived Sleep Quality',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (selectedRating != null)
              Text(
                Formatters.formatQualityLabel(selectedRating),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getColorForRating(selectedRating!),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = selectedRating == rating;
            final ratingColor = _getColorForRating(rating);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < 4 ? 8.0 : 0.0,
                ),
                child: InkWell(
                  onTap: () => onRatingChanged(rating),
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ratingColor.withOpacity(0.18)
                          : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected
                            ? ratingColor
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      rating.toString(),
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected
                            ? ratingColor
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getColorForRating(int rating) {
    switch (rating) {
      case 1:
        return AppColors.quality1;
      case 2:
        return AppColors.quality2;
      case 3:
        return AppColors.quality3;
      case 4:
        return AppColors.quality4;
      case 5:
        return AppColors.quality5;
      default:
        return AppColors.dustyBlue;
    }
  }
}


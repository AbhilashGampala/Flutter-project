import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class SomnaBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const SomnaBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBg = color ?? (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle);
    final effectiveText = textColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: effectiveText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


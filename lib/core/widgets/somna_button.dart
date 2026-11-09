import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum SomnaButtonVariant { primary, secondary, outline, destructive }

class SomnaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SomnaButtonVariant variant;
  final Widget? leadingIcon;
  final bool isLoading;
  final double? width;

  const SomnaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SomnaButtonVariant.primary,
    this.leadingIcon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case SomnaButtonVariant.primary:
        bg = isDark ? AppColors.dustyBlue : AppColors.brandPrimary;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case SomnaButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        );
        break;
      case SomnaButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        );
        break;
      case SomnaButtonVariant.destructive:
        bg = AppColors.mutedCoral.withOpacity(0.12);
        fg = AppColors.mutedCoral;
        border = const BorderSide(color: AppColors.mutedCoral);
        break;
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (leadingIcon != null) ...[
          leadingIcon!,
          const SizedBox(width: 10),
        ],
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: child,
      ),
    );
  }
}


import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SomnaProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0+
  final double size;
  final double strokeWidth;
  final Widget? centerWidget;
  final Color? progressColor;
  final Color? trackColor;

  const SomnaProgressRing({
    super.key,
    required this.progress,
    this.size = 200.0,
    this.strokeWidth = 10.0,
    this.centerWidget,
    this.progressColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveTrack = trackColor ??
        (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle);
    final effectiveProgress = progressColor ??
        (progress >= 1.0 ? AppColors.mutedSage : AppColors.dustyBlue);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.5),
              strokeWidth: strokeWidth,
              trackColor: effectiveTrack,
              progressColor: effectiveProgress,
            ),
          ),
          if (centerWidget != null) centerWidget!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track arc (start at 135 deg to 405 deg = 270 deg span)
    const double startAngle = 0.75 * math.pi; // 135 degrees
    const double sweepAngle = 1.5 * math.pi; // 270 degrees

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final double actualSweep = sweepAngle * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        actualSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}


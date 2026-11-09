import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/somna_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Privacy & Local Storage')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SleepTrack Privacy Charter',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 26,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your sleep data is deeply personal. SleepTrack is built from the ground up on local-first principles.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPillar(
                      Icons.storage_outlined,
                      '100% Local Device Storage',
                      'All sleep logs, timestamps, notes, and preference configurations reside directly on your phone in a local SQLite database.',
                      isDark,
                    ),
                    const Divider(height: 28),
                    _buildPillar(
                      Icons.cloud_off_outlined,
                      'Zero Remote Transmission',
                      'SleepTrack makes no outbound network connections to external analytics, telemetries, or ad networks.',
                      isDark,
                    ),
                    const Divider(height: 28),
                    _buildPillar(
                      Icons.file_download_outlined,
                      'Unfettered Data Ownership',
                      'You can export your full sleep history as RFC 4180 CSV or JSON anytime, or wipe the entire database with a single click.',
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillar(IconData icon, String title, String desc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


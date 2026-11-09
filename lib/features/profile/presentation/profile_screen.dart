import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_card.dart';
import '../../../shared/state/app_state_provider.dart';
import '../../data_management/presentation/data_management_screen.dart';
import '../../settings/presentation/privacy_screen.dart';
import '../../settings/presentation/reminder_settings_screen.dart';
import '../../settings/presentation/schedule_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showThemeSelector(BuildContext context) {
    final state = context.read<AppStateProvider>();
    final current = state.preferences.themeModeString;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _buildThemeRadio(ctx, state, 'System Default', 'system', current),
                _buildThemeRadio(ctx, state, 'Light Theme', 'light', current),
                _buildThemeRadio(ctx, state, 'Midnight Dark Theme', 'dark', current),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeRadio(
    BuildContext ctx,
    AppStateProvider state,
    String label,
    String value,
    String current,
  ) {
    return ListTile(
      title: Text(label, style: AppTypography.bodyLarge),
      trailing: current == value ? const Icon(Icons.check, color: AppColors.dustyBlue) : null,
      onTap: () {
        state.setThemeMode(value);
        Navigator.of(ctx).pop();
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About SleepTrack'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appTagline,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Version: ${AppConstants.appVersion}\nArchitecture: Local-first SQLite\nPrivacy: 100% Offline, Zero Tracking',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();
    final prefs = state.preferences;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Header Card
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_outline,
                        size: 28,
                        color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sleep Profile',
                            style: AppTypography.headlineSmall.copyWith(
                              fontSize: 18,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal: ${TimeUtils.formatDurationMinutes(prefs.sleepGoalMinutes)} • ${state.sessions.length} sessions logged',
                            style: AppTypography.labelMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Sleep Configuration Section
              Text(
                'Sleep Schedule',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SomnaCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      Icons.tune_outlined,
                      'Goal & Schedule',
                      'Target: ${TimeUtils.formatDurationMinutes(prefs.sleepGoalMinutes)} (${TimeUtils.formatTimeFromMinutes(prefs.preferredBedtimeMinutes)} - ${TimeUtils.formatTimeFromMinutes(prefs.preferredWakeMinutes)})',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScheduleSettingsScreen()),
                        );
                      },
                      isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      Icons.notifications_none_outlined,
                      'Bedtime & Wake Reminders',
                      prefs.bedtimeReminderEnabled ? 'Active' : 'Disabled',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()),
                        );
                      },
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Preferences & Storage Section
              Text(
                'Application & Data',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SomnaCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      Icons.palette_outlined,
                      'Theme & Appearance',
                      prefs.themeModeString == 'dark'
                          ? 'Midnight Dark'
                          : prefs.themeModeString == 'light'
                              ? 'Light'
                              : 'System Default',
                      () => _showThemeSelector(context),
                      isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      Icons.save_alt_outlined,
                      'Data Management & Export',
                      'Export CSV/JSON, seed data, reset',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DataManagementScreen()),
                        );
                      },
                      isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      Icons.shield_outlined,
                      'Privacy & Storage Policy',
                      '100% offline, local SQLite',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                        );
                      },
                      isDark,
                    ),
                    const Divider(height: 1),
                    _buildSettingsItem(
                      Icons.info_outline,
                      'About SleepTrack',
                      'v${AppConstants.appVersion}',
                      () => _showAboutDialog(context),
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      leading: Icon(icon, color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary),
      title: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.labelMedium.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
      onTap: onTap,
    );
  }
}


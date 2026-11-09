import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_card.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/state/app_state_provider.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late bool _bedtimeEnabled;
  late bool _wakeEnabled;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AppStateProvider>().preferences;
    _bedtimeEnabled = prefs.bedtimeReminderEnabled;
    _wakeEnabled = prefs.wakeReminderEnabled;
  }

  Future<void> _toggleBedtime(bool enabled) async {
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    }
    setState(() => _bedtimeEnabled = enabled);
    final state = context.read<AppStateProvider>();
    final updated = state.preferences.copyWith(bedtimeReminderEnabled: enabled);
    await state.updatePreferences(updated);
  }

  Future<void> _toggleWake(bool enabled) async {
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    }
    setState(() => _wakeEnabled = enabled);
    final state = context.read<AppStateProvider>();
    final updated = state.preferences.copyWith(wakeReminderEnabled: enabled);
    await state.updatePreferences(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prefs = context.watch<AppStateProvider>().preferences;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Sleep Reminders')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local Sleep Reminders',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SleepTrack delivers gentle notifications purely from your device hardware to keep your circadian rhythm consistent without external servers.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Bedtime Reminder Card
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bedtime Wind-Down Reminder',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Triggers daily at ${TimeUtils.formatTimeFromMinutes(prefs.preferredBedtimeMinutes)} to start your nighttime routine.',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _bedtimeEnabled,
                      activeColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                      onChanged: _toggleBedtime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Wake-up Reminder Card
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wake-Up Log Reminder',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Triggers daily at ${TimeUtils.formatTimeFromMinutes(prefs.preferredWakeMinutes)} prompting you to finalize or log your sleep.',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _wakeEnabled,
                      activeColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                      onChanged: _toggleWake,
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
}


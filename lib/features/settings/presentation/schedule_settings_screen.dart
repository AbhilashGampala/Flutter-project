import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_button.dart';
import '../../../core/widgets/somna_card.dart';
import '../../../shared/state/app_state_provider.dart';

class ScheduleSettingsScreen extends StatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  late int _goalMinutes;
  late int _bedtimeMinutes;
  late int _wakeMinutes;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AppStateProvider>().preferences;
    _goalMinutes = prefs.sleepGoalMinutes;
    _bedtimeMinutes = prefs.preferredBedtimeMinutes;
    _wakeMinutes = prefs.preferredWakeMinutes;
  }

  Future<void> _save() async {
    final state = context.read<AppStateProvider>();
    final updated = state.preferences.copyWith(
      sleepGoalMinutes: _goalMinutes,
      preferredBedtimeMinutes: _bedtimeMinutes,
      preferredWakeMinutes: _wakeMinutes,
    );
    await state.updatePreferences(updated);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Sleep Goal & Schedule')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Section
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Sleep Goal',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target duration used to measure daily sleep deficit and goal attainment.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        TimeUtils.formatDurationMinutes(_goalMinutes),
                        style: AppTypography.heroDuration.copyWith(
                          fontSize: 36,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.brandPrimary,
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                        thumbColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                      ),
                      child: Slider(
                        value: _goalMinutes.toDouble(),
                        min: 300,
                        max: 600,
                        divisions: 20,
                        onChanged: (val) {
                          setState(() => _goalMinutes = val.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Schedule Section
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTimePickerRow(
                      'Target Bedtime',
                      _bedtimeMinutes,
                      () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: _bedtimeMinutes ~/ 60,
                            minute: _bedtimeMinutes % 60,
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _bedtimeMinutes = picked.hour * 60 + picked.minute;
                          });
                        }
                      },
                      isDark,
                    ),
                    const Divider(height: 28),
                    _buildTimePickerRow(
                      'Target Wake Time',
                      _wakeMinutes,
                      () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: _wakeMinutes ~/ 60,
                            minute: _wakeMinutes % 60,
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _wakeMinutes = picked.hour * 60 + picked.minute;
                          });
                        }
                      },
                      isDark,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Save Action
              SomnaButton(
                label: 'Save Changes',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerRow(String label, int minutes, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  TimeUtils.formatTimeFromMinutes(minutes),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


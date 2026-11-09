import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_button.dart';
import '../../../core/widgets/somna_card.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/state/app_state_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding configuration values
  int _goalMinutes = 480; // 8 hours
  int _bedtimeMinutes = 23 * 60; // 23:00
  int _wakeMinutes = 7 * 60; // 07:00
  bool _enableReminders = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final state = context.read<AppStateProvider>();
    final newPrefs = state.preferences.copyWith(
      sleepGoalMinutes: _goalMinutes,
      preferredBedtimeMinutes: _bedtimeMinutes,
      preferredWakeMinutes: _wakeMinutes,
      bedtimeReminderEnabled: _enableReminders,
      wakeReminderEnabled: _enableReminders,
      onboardingCompleted: true,
    );
    await state.updatePreferences(newPrefs);
    await state.completeOnboarding();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: List.generate(4, (index) {
                  final isCurrent = _currentPage == index;
                  final isPast = _currentPage > index;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 3 ? 8.0 : 0.0),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark ? AppColors.dustyBlue : AppColors.brandPrimary)
                            : isPast
                                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(isDark),
                  _buildGoalPage(isDark),
                  _buildSchedulePage(isDark),
                  _buildRemindersPage(isDark),
                ],
              ),
            ),

            // Bottom Navigation Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SomnaButton(
                label: _currentPage == 3 ? 'Get Started' : 'Continue',
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bedtime_outlined,
              size: 32,
              color: isDark ? AppColors.darkTextPrimary : AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'SleepTrack',
            style: AppTypography.displayLarge.copyWith(
              letterSpacing: -1.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Understand your natural sleep rhythms with quiet, private, and mathematically sound tracking.',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SomnaCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildValueRow(
                  Icons.shield_outlined,
                  '100% Private & Local',
                  'Your sleep records never leave your device. No cloud account or subscription required.',
                  isDark,
                ),
                const Divider(height: 24),
                _buildValueRow(
                  Icons.auto_graph_outlined,
                  'Circadian Analytics',
                  'True circular mathematics for midnight consistency, sleep debt, and duration trends.',
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(IconData icon, String title, String desc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary),
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

  Widget _buildGoalPage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Your Daily Sleep Goal',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 28,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Most healthy adults require between 7 and 9 hours of sleep each night for restorative recovery.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  TimeUtils.formatDurationMinutes(_goalMinutes),
                  style: AppTypography.heroDuration.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recommended: 8h 00m',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.dustyBlue : AppColors.dustyBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
              inactiveTrackColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
              thumbColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
              trackHeight: 6,
            ),
            child: Slider(
              value: _goalMinutes.toDouble(),
              min: 300, // 5h
              max: 600, // 10h
              divisions: 20, // 15-minute intervals
              onChanged: (val) {
                setState(() {
                  _goalMinutes = val.toInt();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Sleep Schedule',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 28,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A stable bedtime anchors your internal circadian pacemaker and sharpens morning cognitive focus.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 36),
          SomnaCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSchedulePickerRow(
                  label: 'Target Bedtime',
                  minutesFromMidnight: _bedtimeMinutes,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: _bedtimeMinutes ~/ 60,
                        minute: _bedtimeMinutes % 60,
                      ),
                    );
                    if (time != null) {
                      setState(() {
                        _bedtimeMinutes = time.hour * 60 + time.minute;
                      });
                    }
                  },
                  isDark: isDark,
                ),
                const Divider(height: 32),
                _buildSchedulePickerRow(
                  label: 'Target Wake Time',
                  minutesFromMidnight: _wakeMinutes,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: _wakeMinutes ~/ 60,
                        minute: _wakeMinutes % 60,
                      ),
                    );
                    if (time != null) {
                      setState(() {
                        _wakeMinutes = time.hour * 60 + time.minute;
                      });
                    }
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePickerRow({
    required String label,
    required int minutesFromMidnight,
    required VoidCallback onTap,
    required bool isDark,
  }) {
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
                  TimeUtils.formatTimeFromMinutes(minutesFromMidnight),
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersPage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gentle Sleep Reminders',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 28,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Receive a quiet notification when your target wind-down window begins, and a reminder to log your sleep upon waking.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 36),
          SomnaCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Daily Reminders',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bedtime at ${TimeUtils.formatTimeFromMinutes(_bedtimeMinutes)} & Wake at ${TimeUtils.formatTimeFromMinutes(_wakeMinutes)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enableReminders,
                  activeColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                  onChanged: (val) {
                    setState(() {
                      _enableReminders = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


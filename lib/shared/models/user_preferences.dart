import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class UserPreferences {
  final int sleepGoalMinutes;
  final int preferredBedtimeMinutes; // Minutes from midnight (e.g. 23:00 = 1380)
  final int preferredWakeMinutes; // Minutes from midnight (e.g. 07:00 = 420)
  final bool bedtimeReminderEnabled;
  final bool wakeReminderEnabled;
  final String themeModeString; // 'system' | 'light' | 'dark'
  final bool onboardingCompleted;

  const UserPreferences({
    this.sleepGoalMinutes = AppConstants.defaultSleepGoalMinutes,
    this.preferredBedtimeMinutes = AppConstants.defaultBedtimeHour * 60 + AppConstants.defaultBedtimeMinute,
    this.preferredWakeMinutes = AppConstants.defaultWakeHour * 60 + AppConstants.defaultWakeMinute,
    this.bedtimeReminderEnabled = false,
    this.wakeReminderEnabled = false,
    this.themeModeString = 'system',
    this.onboardingCompleted = false,
  });

  ThemeMode get themeMode {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  UserPreferences copyWith({
    int? sleepGoalMinutes,
    int? preferredBedtimeMinutes,
    int? preferredWakeMinutes,
    bool? bedtimeReminderEnabled,
    bool? wakeReminderEnabled,
    String? themeModeString,
    bool? onboardingCompleted,
  }) {
    return UserPreferences(
      sleepGoalMinutes: sleepGoalMinutes ?? this.sleepGoalMinutes,
      preferredBedtimeMinutes: preferredBedtimeMinutes ?? this.preferredBedtimeMinutes,
      preferredWakeMinutes: preferredWakeMinutes ?? this.preferredWakeMinutes,
      bedtimeReminderEnabled: bedtimeReminderEnabled ?? this.bedtimeReminderEnabled,
      wakeReminderEnabled: wakeReminderEnabled ?? this.wakeReminderEnabled,
      themeModeString: themeModeString ?? this.themeModeString,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sleep_goal_minutes': sleepGoalMinutes,
      'preferred_bedtime_minutes': preferredBedtimeMinutes,
      'preferred_wake_minutes': preferredWakeMinutes,
      'bedtime_reminder_enabled': bedtimeReminderEnabled ? 1 : 0,
      'wake_reminder_enabled': wakeReminderEnabled ? 1 : 0,
      'theme_mode': themeModeString,
      'onboarding_completed': onboardingCompleted ? 1 : 0,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      sleepGoalMinutes: (map['sleep_goal_minutes'] as int?) ?? AppConstants.defaultSleepGoalMinutes,
      preferredBedtimeMinutes: (map['preferred_bedtime_minutes'] as int?) ??
          (AppConstants.defaultBedtimeHour * 60 + AppConstants.defaultBedtimeMinute),
      preferredWakeMinutes: (map['preferred_wake_minutes'] as int?) ??
          (AppConstants.defaultWakeHour * 60 + AppConstants.defaultWakeMinute),
      bedtimeReminderEnabled: (map['bedtime_reminder_enabled'] as int?) == 1,
      wakeReminderEnabled: (map['wake_reminder_enabled'] as int?) == 1,
      themeModeString: (map['theme_mode'] as String?) ?? 'system',
      onboardingCompleted: (map['onboarding_completed'] as int?) == 1,
    );
  }
}


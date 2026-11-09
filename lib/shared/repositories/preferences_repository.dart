import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_preferences.dart';
import '../services/database_service.dart';

abstract class IPreferencesRepository {
  Future<UserPreferences> getPreferences();
  Future<void> savePreferences(UserPreferences preferences);
  Future<void> resetPreferences();
}

class PreferencesRepository implements IPreferencesRepository {
  final DatabaseService _dbService;

  PreferencesRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  static const String _keySleepGoal = 'somna_pref_sleep_goal';
  static const String _keyBedtime = 'somna_pref_bedtime';
  static const String _keyWakeTime = 'somna_pref_waketime';
  static const String _keyBedtimeReminder = 'somna_pref_bedtime_reminder';
  static const String _keyWakeReminder = 'somna_pref_wake_reminder';
  static const String _keyThemeMode = 'somna_pref_theme_mode';
  static const String _keyOnboardingDone = 'somna_pref_onboarding_done';

  @override
  Future<UserPreferences> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keySleepGoal)) {
        return UserPreferences(
          sleepGoalMinutes: prefs.getInt(_keySleepGoal) ?? AppConstants.defaultSleepGoalMinutes,
          preferredBedtimeMinutes: prefs.getInt(_keyBedtime) ?? (AppConstants.defaultBedtimeHour * 60),
          preferredWakeMinutes: prefs.getInt(_keyWakeTime) ?? (AppConstants.defaultWakeHour * 60),
          bedtimeReminderEnabled: prefs.getBool(_keyBedtimeReminder) ?? false,
          wakeReminderEnabled: prefs.getBool(_keyWakeReminder) ?? false,
          themeModeString: prefs.getString(_keyThemeMode) ?? 'system',
          onboardingCompleted: prefs.getBool(_keyOnboardingDone) ?? false,
        );
      }
    } catch (_) {
      // Fallback to SQLite
    }

    final dbPrefs = await _dbService.getPreferences();
    return dbPrefs ?? const UserPreferences();
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keySleepGoal, preferences.sleepGoalMinutes);
      await prefs.setInt(_keyBedtime, preferences.preferredBedtimeMinutes);
      await prefs.setInt(_keyWakeTime, preferences.preferredWakeMinutes);
      await prefs.setBool(_keyBedtimeReminder, preferences.bedtimeReminderEnabled);
      await prefs.setBool(_keyWakeReminder, preferences.wakeReminderEnabled);
      await prefs.setString(_keyThemeMode, preferences.themeModeString);
      await prefs.setBool(_keyOnboardingDone, preferences.onboardingCompleted);
    } catch (_) {}

    await _dbService.savePreferences(preferences);
  }

  @override
  Future<void> resetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    await _dbService.savePreferences(const UserPreferences());
  }
}


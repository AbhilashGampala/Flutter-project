class AppConstants {
  static const String appName = 'SleepTrack';
  static const String appTagline = 'Calm, private, science-grounded sleep tracking';
  static const String appVersion = '1.0.0';

  // Default Sleep Parameters
  static const int defaultSleepGoalMinutes = 480; // 8 hours
  static const int minSleepGoalMinutes = 240; // 4 hours
  static const int maxSleepGoalMinutes = 720; // 12 hours

  // Default Schedule: 23:00 to 07:00
  static const int defaultBedtimeHour = 23;
  static const int defaultBedtimeMinute = 0;
  static const int defaultWakeHour = 7;
  static const int defaultWakeMinute = 0;

  // Notification Channel IDs
  static const String notificationChannelId = 'sleeptrack_reminders';
  static const String notificationChannelName = 'SleepTrack Reminders';
  static const String notificationChannelDesc = 'Reminders for your scheduled bedtime and wake-up times';

  static const int bedtimeNotificationId = 1001;
  static const int wakeNotificationId = 1002;

  // Database
  static const String databaseName = 'sleeptrack.db';
  static const int databaseVersion = 1;

  // Session source types
  static const String sourceTimer = 'timer';
  static const String sourceManual = 'manual';

  // Quality Ratings
  static const int minRating = 1;
  static const int maxRating = 5;
}


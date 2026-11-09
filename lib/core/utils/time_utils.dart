import 'package:intl/intl.dart';

class TimeUtils {
  static String formatDurationMinutes(int totalMinutes) {
    if (totalMinutes < 0) totalMinutes = 0;
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (hours == 0) {
      return '${minutes}m';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  static String formatDurationDetailed(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    final String hStr = hours.toString().padLeft(2, '0');
    final String mStr = minutes.toString().padLeft(2, '0');
    final String sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  static String formatTimeOfDay(DateTime dateTime, {bool use24Hour = true}) {
    if (use24Hour) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('h:mm a').format(dateTime);
  }

  static String formatTimeFromMinutes(int minutesFromMidnight, {bool use24Hour = true}) {
    final int normalized = ((minutesFromMidnight % 1440) + 1440) % 1440;
    final int hours = normalized ~/ 60;
    final int minutes = normalized % 60;
    final DateTime now = DateTime.now();
    final DateTime dt = DateTime(now.year, now.month, now.day, hours, minutes);
    return formatTimeOfDay(dt, use24Hour: use24Hour);
  }

  static String formatDateElegantly(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (target == today) {
      return 'Today, ${DateFormat('MMM d').format(dateTime)}';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('MMM d').format(dateTime)}';
    }
    return DateFormat('EEE, MMM d').format(dateTime);
  }

  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, y').format(dateTime);
  }

  static String formatShortDay(DateTime dateTime) {
    return DateFormat('E').format(dateTime); // e.g., Mon
  }

  static String getGreeting({DateTime? time}) {
    final DateTime target = time ?? DateTime.now();
    final int hour = target.hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static DateTime endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}


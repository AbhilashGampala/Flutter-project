class Formatters {
  static String formatQualityLabel(int? rating) {
    switch (rating) {
      case 1:
        return 'Restless';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Restful';
      case 5:
        return 'Optimal';
      default:
        return 'Unrated';
    }
  }

  static String formatPercent(double value) {
    return '${value.clamp(0.0, 100.0).toStringAsFixed(0)}%';
  }

  static String formatMinutesDifference(int differenceMinutes) {
    if (differenceMinutes == 0) return 'On track';
    final String sign = differenceMinutes > 0 ? '+' : '-';
    final int absMin = differenceMinutes.abs();
    final int h = absMin ~/ 60;
    final int m = absMin % 60;
    if (h == 0) {
      return '$sign${m}m';
    }
    if (m == 0) {
      return '$sign${h}h';
    }
    return '$sign${h}h ${m}m';
  }
}


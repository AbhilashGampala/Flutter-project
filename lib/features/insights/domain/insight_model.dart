enum InsightType {
  duration,
  consistency,
  schedule,
  goal,
  trend,
}

enum InsightLevel {
  positive,
  neutral,
  attention,
}

class InsightItem {
  final String id;
  final InsightType type;
  final InsightLevel level;
  final String title;
  final String message;
  final String timePeriod;
  final String metricExplanation;

  const InsightItem({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.message,
    required this.timePeriod,
    required this.metricExplanation,
  });
}


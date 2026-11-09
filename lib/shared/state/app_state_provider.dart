import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/somna_duration_bar_chart.dart';
import '../../features/analytics/domain/analytics_calculator.dart';
import '../../features/analytics/domain/analytics_models.dart';
import '../../features/insights/domain/insight_generator.dart';
import '../../features/insights/domain/insight_model.dart';
import '../models/active_session.dart';
import '../models/sleep_session.dart';
import '../models/user_preferences.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/sleep_repository.dart';
import '../services/notification_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ISleepRepository _sleepRepository;
  final IPreferencesRepository _preferencesRepository;
  final NotificationService _notificationService;

  AppStateProvider({
    ISleepRepository? sleepRepository,
    IPreferencesRepository? preferencesRepository,
    NotificationService? notificationService,
  })  : _sleepRepository = sleepRepository ?? SleepRepository(),
        _preferencesRepository = preferencesRepository ?? PreferencesRepository(),
        _notificationService = notificationService ?? NotificationService.instance;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  List<SleepSession> _sessions = [];
  List<SleepSession> get sessions => List.unmodifiable(_sessions);

  ActiveSession? _activeSession;
  ActiveSession? get activeSession => _activeSession;
  bool get isTrackingActive => _activeSession != null;

  UserPreferences _preferences = const UserPreferences();
  UserPreferences get preferences => _preferences;

  // Cached Computed Metrics
  SleepSummaryStats _summaryStats = SleepSummaryStats.empty;
  SleepSummaryStats get summaryStats => _summaryStats;

  SleepDebtInfo _sleepDebt = SleepDebtInfo.empty;
  SleepDebtInfo get sleepDebt => _sleepDebt;

  List<TagImpact> _tagImpacts = [];
  List<TagImpact> get tagImpacts => List.unmodifiable(_tagImpacts);

  List<InsightItem> _insights = [];
  List<InsightItem> get insights => List.unmodifiable(_insights);

  List<DailyChartData> _weeklyChartData = [];
  List<DailyChartData> get weeklyChartData => List.unmodifiable(_weeklyChartData);

  SleepSession? get latestSession => _sessions.isNotEmpty ? _sessions.first : null;

  Timer? _activeSessionTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _preferences = await _preferencesRepository.getPreferences();
    _sessions = await _sleepRepository.getAllSessions();
    _activeSession = await _sleepRepository.getActiveSession();

    // Check if recovered active session is stale (> 24 hours)
    if (_activeSession != null && _activeSession!.isStale) {
      await _sleepRepository.clearActiveSession();
      _activeSession = null;
    } else if (_activeSession != null) {
      _startActiveSessionTicker();
    }

    _recomputeMetrics();
    _isInitialized = true;
    notifyListeners();
  }

  void _recomputeMetrics() {
    _summaryStats = AnalyticsCalculator.calculateSummary(
      _sessions,
      _preferences.sleepGoalMinutes,
    );
    _sleepDebt = AnalyticsCalculator.calculateSleepDebt(
      _sessions,
      _preferences.sleepGoalMinutes,
    );
    _tagImpacts = AnalyticsCalculator.calculateTagImpacts(_sessions);
    _insights = InsightGenerator.generate(
      sessions: _sessions,
      goalMinutes: _preferences.sleepGoalMinutes,
    );
    _weeklyChartData = AnalyticsCalculator.buildWeeklyChartData(_sessions);
  }

  void _startActiveSessionTicker() {
    _activeSessionTimer?.cancel();
    _activeSessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _stopActiveSessionTicker() {
    _activeSessionTimer?.cancel();
    _activeSessionTimer = null;
  }

  // --- Active Sleep Tracking Actions ---

  Future<void> startSleepSession() async {
    if (_activeSession != null) return;

    final active = ActiveSession(startTimestamp: DateTime.now());
    await _sleepRepository.saveActiveSession(active);
    _activeSession = active;
    _startActiveSessionTicker();
    notifyListeners();
  }

  Future<SleepSession> wakeUpAndFinalizeSession({
    int? qualityRating,
    String? notes,
    List<String>? tags,
  }) async {
    if (_activeSession == null) {
      throw StateError('No active sleep session to finalize.');
    }

    final DateTime start = _activeSession!.startTimestamp;
    final DateTime end = DateTime.now();

    final DateTime effectiveEnd = end.difference(start).inSeconds < 60
        ? start.add(const Duration(minutes: 1))
        : end;

    final session = SleepSession(
      startTimestamp: start,
      endTimestamp: effectiveEnd,
      qualityRating: qualityRating,
      notes: notes ?? _activeSession!.notes,
      tags: tags ?? const [],
      source: AppConstants.sourceTimer,
    );

    final saved = await _sleepRepository.addSession(session);
    await _sleepRepository.clearActiveSession();
    _activeSession = null;
    _stopActiveSessionTicker();

    _sessions = await _sleepRepository.getAllSessions();
    _recomputeMetrics();
    notifyListeners();
    return saved;
  }

  Future<void> discardActiveSession() async {
    if (_activeSession == null) return;
    await _sleepRepository.clearActiveSession();
    _activeSession = null;
    _stopActiveSessionTicker();
    notifyListeners();
  }

  // --- Manual Session Actions ---

  Future<SleepSession> addManualSession({
    required DateTime startTimestamp,
    required DateTime endTimestamp,
    int? qualityRating,
    String? notes,
    List<String>? tags,
  }) async {
    final session = SleepSession(
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp,
      qualityRating: qualityRating,
      notes: notes,
      tags: tags ?? const [],
      source: AppConstants.sourceManual,
    );

    final saved = await _sleepRepository.addSession(session);
    _sessions = await _sleepRepository.getAllSessions();
    _recomputeMetrics();
    notifyListeners();
    return saved;
  }

  Future<void> updateSession(SleepSession session) async {
    await _sleepRepository.updateSession(session);
    _sessions = await _sleepRepository.getAllSessions();
    _recomputeMetrics();
    notifyListeners();
  }

  Future<void> deleteSession(int id) async {
    await _sleepRepository.deleteSession(id);
    _sessions = await _sleepRepository.getAllSessions();
    _recomputeMetrics();
    notifyListeners();
  }

  // --- Preferences & Settings ---

  Future<void> updatePreferences(UserPreferences newPrefs) async {
    _preferences = newPrefs;
    await _preferencesRepository.savePreferences(newPrefs);
    _recomputeMetrics();

    if (_preferences.bedtimeReminderEnabled) {
      final hour = _preferences.preferredBedtimeMinutes ~/ 60;
      final minute = _preferences.preferredBedtimeMinutes % 60;
      await _notificationService.scheduleBedtimeReminder(hour: hour, minute: minute);
    } else {
      await _notificationService.cancelBedtimeReminder();
    }

    if (_preferences.wakeReminderEnabled) {
      final hour = _preferences.preferredWakeMinutes ~/ 60;
      final minute = _preferences.preferredWakeMinutes % 60;
      await _notificationService.scheduleWakeReminder(hour: hour, minute: minute);
    } else {
      await _notificationService.cancelWakeReminder();
    }

    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _preferences = _preferences.copyWith(onboardingCompleted: true);
    await _preferencesRepository.savePreferences(_preferences);
    notifyListeners();
  }

  Future<void> setThemeMode(String themeModeString) async {
    _preferences = _preferences.copyWith(themeModeString: themeModeString);
    await _preferencesRepository.savePreferences(_preferences);
    notifyListeners();
  }

  // --- Data Management & Seeding ---

  Future<void> clearAllData() async {
    await _sleepRepository.deleteAllSessions();
    await _sleepRepository.clearActiveSession();
    _activeSession = null;
    _stopActiveSessionTicker();
    _sessions.clear();
    _recomputeMetrics();
    notifyListeners();
  }

  /// Seeds realistic 14-day historical sleep data for instant testing & evaluation
  Future<void> seedRealisticSampleData() async {
    await _sleepRepository.deleteAllSessions();

    final now = DateTime.now();
    final List<Map<String, dynamic>> samples = [
      {'daysAgo': 1, 'bedH': 23, 'bedM': 15, 'wakeH': 7, 'wakeM': 30, 'rating': 4, 'tags': ['Reading', 'Cool Room'], 'notes': 'Woke up refreshed.'},
      {'daysAgo': 2, 'bedH': 23, 'bedM': 45, 'wakeH': 7, 'wakeM': 15, 'rating': 3, 'tags': ['Workout'], 'notes': 'Read book before bed.'},
      {'daysAgo': 3, 'bedH': 0, 'bedM': 10, 'wakeH': 7, 'wakeM': 45, 'rating': 3, 'tags': ['Late Meal', 'Screen Time'], 'notes': 'Watched a movie late.'},
      {'daysAgo': 4, 'bedH': 23, 'bedM': 0, 'wakeH': 7, 'wakeM': 20, 'rating': 5, 'tags': ['Meditation', 'Cool Room'], 'notes': 'Consistent schedule.'},
      {'daysAgo': 5, 'bedH': 22, 'bedM': 50, 'wakeH': 7, 'wakeM': 0, 'rating': 4, 'tags': ['Reading'], 'notes': 'Great evening wind-down.'},
      {'daysAgo': 6, 'bedH': 23, 'bedM': 30, 'wakeH': 8, 'wakeM': 0, 'rating': 4, 'tags': ['Cool Room'], 'notes': 'Weekend rest.'},
      {'daysAgo': 7, 'bedH': 0, 'bedM': 30, 'wakeH': 9, 'wakeM': 0, 'rating': 3, 'tags': ['Caffeine'], 'notes': 'Late Saturday night.'},
      {'daysAgo': 8, 'bedH': 23, 'bedM': 10, 'wakeH': 7, 'wakeM': 10, 'rating': 4, 'tags': ['Workout', 'Reading'], 'notes': null},
      {'daysAgo': 9, 'bedH': 23, 'bedM': 5, 'wakeH': 7, 'wakeM': 25, 'rating': 5, 'tags': ['Meditation'], 'notes': 'Fell asleep quickly.'},
      {'daysAgo': 10, 'bedH': 23, 'bedM': 40, 'wakeH': 6, 'wakeM': 50, 'rating': 2, 'tags': ['Caffeine', 'Late Meal'], 'notes': 'Noisy night.'},
      {'daysAgo': 11, 'bedH': 22, 'bedM': 45, 'wakeH': 7, 'wakeM': 15, 'rating': 4, 'tags': ['Cool Room'], 'notes': null},
      {'daysAgo': 12, 'bedH': 23, 'bedM': 20, 'wakeH': 7, 'wakeM': 30, 'rating': 4, 'tags': ['Workout'], 'notes': 'Tired from gym.'},
      {'daysAgo': 13, 'bedH': 23, 'bedM': 0, 'wakeH': 7, 'wakeM': 0, 'rating': 4, 'tags': ['Reading'], 'notes': null},
      {'daysAgo': 14, 'bedH': 23, 'bedM': 15, 'wakeH': 7, 'wakeM': 30, 'rating': 5, 'tags': ['Meditation', 'Cool Room'], 'notes': 'Peaceful sleep.'},
    ];

    for (final s in samples) {
      final daysAgo = s['daysAgo'] as int;
      final bedH = s['bedH'] as int;
      final bedM = s['bedM'] as int;
      final wakeH = s['wakeH'] as int;
      final wakeM = s['wakeM'] as int;

      final targetDay = now.subtract(Duration(days: daysAgo));
      final wakeDay = DateTime(targetDay.year, targetDay.month, targetDay.day, wakeH, wakeM);
      final bedDay = bedH >= 18
          ? wakeDay.subtract(const Duration(days: 1))
          : wakeDay;
      final start = DateTime(bedDay.year, bedDay.month, bedDay.day, bedH, bedM);

      final session = SleepSession(
        startTimestamp: start,
        endTimestamp: wakeDay,
        qualityRating: s['rating'] as int?,
        notes: s['notes'] as String?,
        tags: (s['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        source: AppConstants.sourceManual,
      );

      await _sleepRepository.addSession(session);
    }

    _sessions = await _sleepRepository.getAllSessions();
    _recomputeMetrics();
    notifyListeners();
  }

  @override
  void dispose() {
    _activeSessionTimer?.cancel();
    super.dispose();
  }
}

import 'package:somna/core/errors/app_exceptions.dart';
import 'package:somna/shared/models/active_session.dart';
import 'package:somna/shared/models/sleep_session.dart';
import 'package:somna/shared/repositories/sleep_repository.dart';

class MockSleepRepository implements ISleepRepository {
  final List<SleepSession> _sessions = [];
  ActiveSession? _activeSession;
  int _counter = 1;

  @override
  Future<List<SleepSession>> getAllSessions() async {
    final list = List<SleepSession>.from(_sessions);
    list.sort((a, b) => b.startTimestamp.compareTo(a.startTimestamp));
    return list;
  }

  @override
  Future<SleepSession> addSession(SleepSession session) async {
    if (!session.startTimestamp.isBefore(session.endTimestamp)) {
      throw const ValidationException('Sleep start time must be before wake-up time.');
    }
    if (session.durationInMinutes < 1) {
      throw const ValidationException('Sleep duration must be at least 1 minute.');
    }
    if (session.durationInMinutes > 1440) {
      throw const ValidationException('Single sleep session cannot exceed 24 hours.');
    }

    final hasOverlap = await checkOverlap(session.startTimestamp, session.endTimestamp);
    if (hasOverlap) {
      throw SessionOverlapException(
        'This session overlaps with an existing sleep record.',
        conflictingStart: session.startTimestamp,
        conflictingEnd: session.endTimestamp,
      );
    }

    final saved = session.copyWith(id: _counter++);
    _sessions.add(saved);
    return saved;
  }

  @override
  Future<void> updateSession(SleepSession session) async {
    if (session.id == null) {
      throw const ValidationException('Cannot update session without ID');
    }
    if (!session.startTimestamp.isBefore(session.endTimestamp)) {
      throw const ValidationException('Sleep start time must be before wake-up time.');
    }

    final hasOverlap = await checkOverlap(
      session.startTimestamp,
      session.endTimestamp,
      excludeId: session.id,
    );
    if (hasOverlap) {
      throw SessionOverlapException(
        'Updated times overlap with another recorded session.',
        conflictingStart: session.startTimestamp,
        conflictingEnd: session.endTimestamp,
      );
    }

    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) {
      _sessions[idx] = session;
    }
  }

  @override
  Future<void> deleteSession(int id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<bool> checkOverlap(DateTime start, DateTime end, {int? excludeId}) async {
    for (final s in _sessions) {
      if (excludeId != null && s.id == excludeId) continue;
      if (s.overlapsWith(start, end)) return true;
    }
    return false;
  }

  @override
  Future<ActiveSession?> getActiveSession() async {
    return _activeSession;
  }

  @override
  Future<void> saveActiveSession(ActiveSession active) async {
    _activeSession = active;
  }

  @override
  Future<void> clearActiveSession() async {
    _activeSession = null;
  }

  @override
  Future<void> deleteAllSessions() async {
    _sessions.clear();
    _activeSession = null;
  }
}


import '../../core/errors/app_exceptions.dart';
import '../models/active_session.dart';
import '../models/sleep_session.dart';
import '../services/database_service.dart';

abstract class ISleepRepository {
  Future<List<SleepSession>> getAllSessions();
  Future<SleepSession> addSession(SleepSession session);
  Future<void> updateSession(SleepSession session);
  Future<void> deleteSession(int id);
  Future<bool> checkOverlap(DateTime start, DateTime end, {int? excludeId});
  Future<ActiveSession?> getActiveSession();
  Future<void> saveActiveSession(ActiveSession active);
  Future<void> clearActiveSession();
  Future<void> deleteAllSessions();
}

class SleepRepository implements ISleepRepository {
  final DatabaseService _dbService;

  SleepRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  @override
  Future<List<SleepSession>> getAllSessions() async {
    return await _dbService.getAllSessions();
  }

  @override
  Future<SleepSession> addSession(SleepSession session) async {
    // Validation: Start must precede End
    if (!session.startTimestamp.isBefore(session.endTimestamp)) {
      throw const ValidationException('Sleep start time must be before wake-up time.');
    }

    // Validation: Duration cannot be negative or absurdly long (> 24 hours)
    if (session.durationInMinutes < 1) {
      throw const ValidationException('Sleep duration must be at least 1 minute.');
    }
    if (session.durationInMinutes > 1440) {
      throw const ValidationException('Single sleep session cannot exceed 24 hours.');
    }

    // Overlap checking
    final overlapping = await _dbService.findOverlappingSessions(
      session.startTimestamp,
      session.endTimestamp,
    );

    if (overlapping.isNotEmpty) {
      final conflict = overlapping.first;
      throw SessionOverlapException(
        'This session overlaps with an existing sleep record.',
        conflictingStart: conflict.startTimestamp,
        conflictingEnd: conflict.endTimestamp,
      );
    }

    final id = await _dbService.insertSession(session);
    return session.copyWith(id: id);
  }

  @override
  Future<void> updateSession(SleepSession session) async {
    if (session.id == null) {
      throw const ValidationException('Cannot update a session without an ID.');
    }
    if (!session.startTimestamp.isBefore(session.endTimestamp)) {
      throw const ValidationException('Sleep start time must be before wake-up time.');
    }

    // Check overlap excluding this session id
    final overlapping = await _dbService.findOverlappingSessions(
      session.startTimestamp,
      session.endTimestamp,
      excludeId: session.id,
    );

    if (overlapping.isNotEmpty) {
      final conflict = overlapping.first;
      throw SessionOverlapException(
        'Updated times overlap with another recorded session.',
        conflictingStart: conflict.startTimestamp,
        conflictingEnd: conflict.endTimestamp,
      );
    }

    await _dbService.updateSession(session);
  }

  @override
  Future<void> deleteSession(int id) async {
    await _dbService.deleteSession(id);
  }

  @override
  Future<bool> checkOverlap(DateTime start, DateTime end, {int? excludeId}) async {
    final list = await _dbService.findOverlappingSessions(start, end, excludeId: excludeId);
    return list.isNotEmpty;
  }

  @override
  Future<ActiveSession?> getActiveSession() async {
    return await _dbService.getActiveSession();
  }

  @override
  Future<void> saveActiveSession(ActiveSession active) async {
    await _dbService.saveActiveSession(active);
  }

  @override
  Future<void> clearActiveSession() async {
    await _dbService.clearActiveSession();
  }

  @override
  Future<void> deleteAllSessions() async {
    await _dbService.deleteAllData();
  }
}


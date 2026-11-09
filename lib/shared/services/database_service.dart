import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/active_session.dart';
import '../models/sleep_session.dart';
import '../models/user_preferences.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;
  String? _customDatabasePath; // Used for testing isolated disk databases

  void setCustomDatabasePath(String? path) {
    _customDatabasePath = path;
    _database = null;
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final String path;
      if (_customDatabasePath != null) {
        path = _customDatabasePath!;
      } else {
        final String dbPath = await getDatabasesPath();
        path = join(dbPath, AppConstants.databaseName);
      }

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize SQLite database: $e', details: e);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Sleep Sessions Table
    await db.execute('''
      CREATE TABLE sleep_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_timestamp INTEGER NOT NULL,
        end_timestamp INTEGER NOT NULL,
        quality_rating INTEGER,
        notes TEXT,
        tags TEXT,
        source TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Indexes for fast chronological and range queries
    await db.execute('''
      CREATE INDEX idx_sleep_start ON sleep_sessions (start_timestamp DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_sleep_end ON sleep_sessions (end_timestamp DESC)
    ''');

    // 2. Active Session Table (Strict persistent single row for interrupted session recovery)
    await db.execute('''
      CREATE TABLE active_session (
        id INTEGER PRIMARY KEY,
        start_timestamp INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 3. User Preferences Table
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY,
        sleep_goal_minutes INTEGER NOT NULL,
        preferred_bedtime_minutes INTEGER NOT NULL,
        preferred_wake_minutes INTEGER NOT NULL,
        bedtime_reminder_enabled INTEGER NOT NULL,
        wake_reminder_enabled INTEGER NOT NULL,
        theme_mode TEXT NOT NULL,
        onboarding_completed INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future schema migrations are handled here in sequence
  }

  // --- CRUD: Sleep Sessions ---

  Future<int> insertSession(SleepSession session) async {
    final db = await database;
    try {
      return await db.insert(
        'sleep_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert sleep session: $e', details: e);
    }
  }

  Future<int> updateSession(SleepSession session) async {
    final db = await database;
    try {
      return await db.update(
        'sleep_sessions',
        session.toMap(),
        where: 'id = ?',
        whereArgs: [session.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update sleep session: $e', details: e);
    }
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'sleep_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete sleep session: $e', details: e);
    }
  }

  Future<List<SleepSession>> getAllSessions() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'sleep_sessions',
        orderBy: 'start_timestamp DESC',
      );
      return maps.map((m) => SleepSession.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Failed to query sleep sessions: $e', details: e);
    }
  }

  Future<List<SleepSession>> findOverlappingSessions(
    DateTime start,
    DateTime end, {
    int? excludeId,
  }) async {
    final db = await database;
    final int startEpoch = start.millisecondsSinceEpoch;
    final int endEpoch = end.millisecondsSinceEpoch;

    String where = 'start_timestamp < ? AND ? < end_timestamp';
    List<dynamic> whereArgs = [endEpoch, startEpoch];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    try {
      final maps = await db.query(
        'sleep_sessions',
        where: where,
        whereArgs: whereArgs,
      );
      return maps.map((m) => SleepSession.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Failed to check overlapping sessions: $e', details: e);
    }
  }

  // --- Active Session ---

  Future<void> saveActiveSession(ActiveSession active) async {
    final db = await database;
    try {
      await db.insert(
        'active_session',
        active.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to save active session: $e', details: e);
    }
  }

  Future<ActiveSession?> getActiveSession() async {
    final db = await database;
    try {
      final maps = await db.query('active_session', limit: 1);
      if (maps.isNotEmpty) {
        return ActiveSession.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to retrieve active session: $e', details: e);
    }
  }

  Future<void> clearActiveSession() async {
    final db = await database;
    try {
      await db.delete('active_session');
    } catch (e) {
      throw DatabaseException('Failed to clear active session: $e', details: e);
    }
  }

  // --- User Preferences ---

  Future<void> savePreferences(UserPreferences prefs) async {
    final db = await database;
    final map = prefs.toMap();
    map['id'] = 1;

    try {
      await db.insert(
        'user_preferences',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to save preferences: $e', details: e);
    }
  }

  Future<UserPreferences?> getPreferences() async {
    final db = await database;
    try {
      final maps = await db.query('user_preferences', where: 'id = 1', limit: 1);
      if (maps.isNotEmpty) {
        return UserPreferences.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to retrieve preferences: $e', details: e);
    }
  }

  // --- Bulk Wipe ---

  Future<void> deleteAllData() async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.delete('sleep_sessions');
        await txn.delete('active_session');
        await txn.delete('user_preferences');
      });
    } catch (e) {
      throw DatabaseException('Failed to bulk delete data: $e', details: e);
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/csv_formatter.dart';
import '../../core/utils/formatters.dart';
import '../models/sleep_session.dart';

class ExportService {
  /// Converts sleep sessions to RFC 4180 CSV string
  static String generateCsv(List<SleepSession> sessions) {
    final List<List<dynamic>> rows = [
      [
        'Session ID',
        'Start Time (ISO)',
        'End Time (ISO)',
        'Duration (Minutes)',
        'Duration (Formatted)',
        'Quality Rating (1-5)',
        'Quality Label',
        'Source',
        'Notes',
        'Created At',
      ]
    ];

    for (final s in sessions) {
      final hours = s.durationInMinutes ~/ 60;
      final minutes = s.durationInMinutes % 60;
      final formattedDuration = '${hours}h ${minutes}m';

      rows.add([
        s.id ?? '',
        s.startTimestamp.toIso8601String(),
        s.endTimestamp.toIso8601String(),
        s.durationInMinutes,
        formattedDuration,
        s.qualityRating ?? '',
        Formatters.formatQualityLabel(s.qualityRating),
        s.source,
        s.notes ?? '',
        s.createdAt.toIso8601String(),
      ]);
    }

    return CsvFormatter.format(rows);
  }

  /// Converts sleep sessions to formatted JSON string
  static String generateJson(List<SleepSession> sessions) {
    final List<Map<String, dynamic>> jsonList = sessions.map((s) => s.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'exportDate': DateTime.now().toIso8601String(),
      'totalSessions': sessions.length,
      'app': 'SleepTrack Sleep Tracker',
      'version': '1.0.0',
      'sessions': jsonList,
    });
  }

  /// Exports data by writing to a temporary file and invoking the system share sheet
  static Future<bool> shareExport({
    required List<SleepSession> sessions,
    required bool isCsv,
  }) async {
    try {
      final String content = isCsv ? generateCsv(sessions) : generateJson(sessions);
      final String extension = isCsv ? 'csv' : 'json';
      final String mimeType = isCsv ? 'text/csv' : 'application/json';

      final tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/sleeptrack_history_$timestamp.$extension';

      final File file = File(filePath);
      await file.writeAsString(content, utf8: true);

      final XFile xFile = XFile(filePath, mimeType: mimeType);
      final ShareResult result = await Share.shareXFiles(
        [xFile],
        subject: 'SleepTrack Sleep History Export',
        text: 'Exported ${sessions.length} sleep sessions from SleepTrack.',
      );

      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Export failed: $e');
      return false;
    }
  }
}


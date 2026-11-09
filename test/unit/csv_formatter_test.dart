import 'package:flutter_test/flutter_test.dart';
import 'package:somna/core/utils/csv_formatter.dart';

void main() {
  group('CsvFormatter RFC 4180 Tests', () {
    test('Standard cells without special characters format normally', () {
      final rows = [
        ['ID', 'Duration', 'Notes'],
        ['1', '480', 'Good night'],
      ];
      final csv = CsvFormatter.format(rows);
      expect(csv, 'ID,Duration,Notes\r\n1,480,Good night\r\n');
    });

    test('Cells with commas are wrapped in quotes', () {
      final rows = [
        ['ID', 'Notes'],
        ['1', 'Had tea, read book'],
      ];
      final csv = CsvFormatter.format(rows);
      expect(csv, 'ID,Notes\r\n1,"Had tea, read book"\r\n');
    });

    test('Cells with quotes are escaped with double-quotes', () {
      final rows = [
        ['ID', 'Notes'],
        ['1', 'Said "goodnight" softly'],
      ];
      final csv = CsvFormatter.format(rows);
      expect(csv, 'ID,Notes\r\n1,"Said ""goodnight"" softly"\r\n');
    });

    test('Cells with newlines are wrapped in quotes', () {
      final rows = [
        ['ID', 'Notes'],
        ['1', 'Line 1\nLine 2'],
      ];
      final csv = CsvFormatter.format(rows);
      expect(csv, 'ID,Notes\r\n1,"Line 1\nLine 2"\r\n');
    });
  });
}


class CsvFormatter {
  /// Encodes a 2D table of strings into an RFC 4180 compliant CSV string.
  /// Fields containing commas, double quotes, or newlines are enclosed in double quotes,
  /// with existing double quotes escaped as `""`.
  static String format(List<List<dynamic>> rows) {
    final StringBuffer buffer = StringBuffer();
    for (int r = 0; r < rows.length; r++) {
      final List<dynamic> row = rows[r];
      for (int c = 0; c < row.length; c++) {
        final dynamic cell = row[c];
        buffer.write(_escapeCell(cell?.toString() ?? ''));
        if (c < row.length - 1) {
          buffer.write(',');
        }
      }
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  static String _escapeCell(String value) {
    final bool needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');

    if (!needsQuotes) {
      return value;
    }

    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}


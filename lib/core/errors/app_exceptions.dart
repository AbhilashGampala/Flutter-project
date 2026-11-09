class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.details});
}

class SessionOverlapException extends AppException {
  final DateTime conflictingStart;
  final DateTime conflictingEnd;

  const SessionOverlapException(
    super.message, {
    required this.conflictingStart,
    required this.conflictingEnd,
    super.code,
    super.details,
  });
}


import 'package:drift/drift.dart'
    show CouldNotRollBackException, DriftWrappedException;
import 'package:sqlite3/sqlite3.dart';

/// A log-safe error wrapper that retains only an error type and optional
/// SQLite result code so sensitive swap data (such as HTLC preimages in
/// SQLite/Drift bind parameters) is never written to plaintext logs.
class RedactedSwapError implements Exception {
  /// Creates a [RedactedSwapError] carrying only a safe [summary].
  const RedactedSwapError(this.summary);

  /// Safe diagnostic summary without exception messages or bound parameters.
  final String summary;

  @override
  String toString() => summary;
}

/// Returns a log-safe summary of [error] without any exception message or SQL
/// bind parameters that could expose secret HTLC preimages.
String formatSafeSwapErrorSummary(Object error) {
  final SqliteException? sqliteError = _unwrapSqliteException(error);
  if (sqliteError != null) {
    final String prefix = identical(sqliteError, error)
        ? '${error.runtimeType}'
        : '${error.runtimeType} -> ${sqliteError.runtimeType}';
    return '$prefix (code=${sqliteError.extendedResultCode})';
  }
  return '${error.runtimeType}';
}

/// Wraps [error] in a [RedactedSwapError] so passing it to `Bloc.addError`
/// logs only a safe type/code summary via `CustomBlocObserver`.
RedactedSwapError sanitizeSwapErrorForLogging(Object error) =>
    RedactedSwapError(formatSafeSwapErrorSummary(error));

SqliteException? _unwrapSqliteException(Object error) {
  Object? current = error;
  for (int depth = 0; depth < 5 && current != null; depth += 1) {
    if (current is SqliteException) {
      return current;
    }
    if (current is DriftWrappedException) {
      current = current.cause;
    } else if (current is CouldNotRollBackException) {
      current = current.cause;
    } else {
      return null;
    }
  }
  return null;
}

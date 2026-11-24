import 'package:drift/drift.dart'
    show CouldNotRollBackException, DriftWrappedException;
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:sqlite3/sqlite3.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';

void main() {
  const String secretPreimage = 'deadbeefcafebabe0123456789abcdef';

  SqliteException buildSensitiveSqliteException() => SqliteException(
    extendedResultCode: 2067,
    message: 'UNIQUE constraint failed: $secretPreimage',
    causingStatement: 'INSERT INTO htlc_swaps VALUES (?)',
    parametersToStatement: <Object?>['{"preimage":"$secretPreimage"}'],
  );

  group('swap_storage_error_sanitizer', () {
    test('redacts direct SqliteException while preserving result code', () {
      final SqliteException error = buildSensitiveSqliteException();
      final RedactedSwapError redacted = sanitizeSwapErrorForLogging(error);

      expect(redacted.toString(), 'SqliteException (code=2067)');
      expect(redacted.toString(), isNot(contains(secretPreimage)));
      expect(redacted.toString(), isNot(contains('INSERT INTO')));
    });

    test('unwraps DriftWrappedException without leaking SQL parameters', () {
      final DriftWrappedException error = DriftWrappedException(
        message: 'failed storing $secretPreimage',
        cause: buildSensitiveSqliteException(),
      );
      final RedactedSwapError redacted = sanitizeSwapErrorForLogging(error);

      expect(
        redacted.toString(),
        'DriftWrappedException -> SqliteException (code=2067)',
      );
      expect(redacted.toString(), isNot(contains(secretPreimage)));
    });

    test(
      'unwraps CouldNotRollBackException without leaking SQL parameters',
      () {
        final CouldNotRollBackException rollbackError =
            CouldNotRollBackException(
              buildSensitiveSqliteException(),
              StackTrace.empty,
              StateError('rollback failed: $secretPreimage'),
            );

        final String summary = formatSafeSwapErrorSummary(rollbackError);
        expect(
          summary,
          'CouldNotRollBackException -> SqliteException (code=2067)',
        );
        expect(summary, isNot(contains(secretPreimage)));
      },
    );

    test('redacts RpcException while preserving numeric error code', () {
      final RpcException error = RpcException(
        -32000,
        'execution reverted: $secretPreimage',
        data: <String, Object?>{'preimage': secretPreimage},
      );
      final RedactedSwapError redacted = sanitizeSwapErrorForLogging(error);

      expect(redacted.toString(), 'RpcException (code=-32000)');
      expect(redacted.toString(), isNot(contains(secretPreimage)));
    });

    test('redacts arbitrary error messages to runtimeType only', () {
      final StateError error = StateError('leak $secretPreimage');
      final RedactedSwapError redacted = sanitizeSwapErrorForLogging(error);

      expect(redacted.toString(), 'StateError');
      expect(redacted.toString(), isNot(contains(secretPreimage)));
    });
  });
}

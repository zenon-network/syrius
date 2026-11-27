import 'dart:math' show pow;
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// String formatting and numeric conversion helpers.
extension StringExtensions on String {
  /// Returns this string with the first character uppercased and the rest
  /// lowercased.
  String capitalize() {
    return '${this[0].toUpperCase()}${toLowerCase().substring(1)}';
  }

  /// Parses this string as a [num].
  num toNum() => num.parse(this);

  /// Converts a decimal string into its integer base-unit [BigInt] using
  /// [decimals] fractional digits.
  BigInt extractDecimals(int decimals) {
    if (!contains('.')) {
      if (decimals == 0 && isEmpty) {
        return BigInt.zero;
      }
      return BigInt.parse(this + ''.padRight(decimals, '0'));
    }
    final List<String> parts = split('.');

    return BigInt.parse(parts[0] +
        (parts[1].length > decimals
            ? parts[1].substring(0, decimals)
            : parts[1].padRight(decimals, '0')),);
  }

  /// Returns this string unchanged.
  String abs() => this;
}

/// Fixed-decimal truncation helpers for [double] values.
extension FixedNumDecimals on double {
  /// Truncates this value to [numDecimals] fractional digits and returns it as
  /// a string.
  String toStringFixedNumDecimals(int numDecimals) {
    return '${(this * pow(10, numDecimals)).truncate() / pow(10, numDecimals)}';
  }
}

/// Token amount formatting helpers for [BigInt] values.
extension BigIntExtensions on BigInt {
  /// Formats this base-unit amount with [decimals] decimal places.
  String addDecimals(int decimals) {

    return AmountUtils.addDecimals(this, decimals);
  }
}

/// Interleaves two lists element by element.
extension ZipTwoLists on List<dynamic> {
  /// Interleaves elements from this list and [smallerList], starting with the
  /// first element of this list and appending any remaining elements after
  /// [smallerList] is exhausted.
  List<T> zip<T>(List<T> smallerList) {
    return fold(
      <T>[],
      (List<T> previousValue, dynamic element) {
        final int elementIndex = indexOf(element);
        previousValue.add(element);
        if (elementIndex < smallerList.length) {
          previousValue.add(
            smallerList[elementIndex],
          );
        }
        return previousValue;
      },
    );
  }
}

/// Abbreviated display helpers for long strings such as addresses and hashes.
extension ShortString on String {
  /// Returns the first 6 and last 6 characters separated by an ellipsis.
  String get short {
    final String longString = this;
    return '${longString.substring(0, 6)}...'
        '${longString.substring(longString.length - 6)}';
  }
}

/// Human-readable formatting helpers for [LedgerError].
extension LedgerErrorExtensions on LedgerError {
  /// Converts this [LedgerError] into a user-facing error description.
  String toFriendlyString() {
    return when(
        connectionError: (String origMessage) => origMessage,
        responseError: _mapStatusWord,);
  }

  String _mapStatusWord(StatusWord statusWord) {
    switch (statusWord) {
      case StatusWord.deny:
        return 'Deny';
      case StatusWord.wrongP1P2:
        return 'Invalid P1 or P2';
      case StatusWord.wrongDataLength:
        return 'Invalid data length';
      case StatusWord.inactiveDevice:
        return 'Device is inactive';
      case StatusWord.notAllowed:
        return 'Request not allowed';
      case StatusWord.insNotSupported:
        return 'Instruction not supported, please make sure the Zenon app is '
            'opened';
      case StatusWord.claNotSupported:
        return 'Class not supported, please make sure the Zenon app is opened';
      case StatusWord.appIsNotOpen:
        return 'App not open, please open the Zenon app on your device';
      case StatusWord.wrongResponseLength:
        return 'Invalid response, please reconnect the device and try again';
      case StatusWord.displayBip32PathFail:
        return 'Failed to display BIP32 path';
      case StatusWord.displayAddressFail:
        return 'Failed to display address';
      case StatusWord.displayAmountFail:
        return 'Failed to display amount';
      case StatusWord.wrongTxLength:
        return 'Invalid transaction length';
      case StatusWord.txParsingFail:
        return 'Failed to parse transaction';
      case StatusWord.txHashFail:
        return 'Failed to hash transaction';
      case StatusWord.badState:
        return 'Bad state, please reconnect the device and try again';
      case StatusWord.signatureFail:
        return 'Failed to create signature';
      case StatusWord.success:
        return 'Success';
      case StatusWord.unknownError:
        return 'Unknown error, please make sure the device is unlocked';
    }
  }
}

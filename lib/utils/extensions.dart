import 'dart:math' show pow;
import 'package:big_decimal/big_decimal.dart';
import 'package:flutter/material.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension StringExtensions on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${toLowerCase().substring(1)}';
  }

  num toNum() => num.parse(this);

  BigInt extractDecimals(int decimals) {
    if (!contains('.')) {
      if (decimals == 0 && isEmpty) {
        return BigInt.zero;
      }
      return BigInt.parse(this + ''.padRight(decimals, '0'));
    }
    final parts = split('.');

    return BigInt.parse(parts[0] +
        (parts[1].length > decimals
            ? parts[1].substring(0, decimals)
            : parts[1].padRight(decimals, '0')),);
  }

  String abs() => this;
}

extension FixedNumDecimals on double {
  String toStringFixedNumDecimals(int numDecimals) {
    return '${(this * pow(10, numDecimals)).truncate() / pow(10, numDecimals)}';
  }
}

extension BigIntExtensions on BigInt {
  String addDecimals(int decimals) {
    return BigDecimal.createAndStripZerosForScale(this, decimals, 0)
        .toPlainString();
  }
}

// This extension takes other list with fewer elements and creates a single one
// by interleaving them, starting with the first element of the first list,
// then the first element of the second list. If second list runs out of elements
// then we continue with the elements from the first list
extension ZipTwoLists on List {
  List<T> zip<T>(List<T> smallerList) {
    return fold(
      <T>[],
      (previousValue, element) {
        final elementIndex = indexOf(element);
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

extension ShortString on String {
  String get short {
    final longString = this;
    return '${longString.substring(0, 6)}...'
        '${longString.substring(longString.length - 6)}';
  }
}

extension LedgerErrorExtensions on LedgerError {
  String toFriendlyString() {
    return when(
        connectionError: (origMessage) => origMessage,
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
        return 'Instruction not supported, please make sure the Zenon app is opened';
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

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

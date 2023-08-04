import 'dart:math' show pow;
import 'package:big_decimal/big_decimal.dart';

extension StringExtensions on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${toLowerCase().substring(1)}';
  }

  num toNum() => num.parse(this);

  BigInt extractDecimals(int decimals) {
    if (!contains('.')) {
      return BigInt.parse(this + ''.padRight(decimals, '0'));
    }
    List<String> parts = split('.');

    return BigInt.parse(parts[0] +
        (parts[1].length > decimals
            ? parts[1].substring(0, decimals)
            : parts[1].padRight(decimals, '0')));
  }
  //BigInt.parse(num.parse(this).toStringAsFixed(decimals).replaceAll('.', ''));

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
        int elementIndex = indexOf(element);
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

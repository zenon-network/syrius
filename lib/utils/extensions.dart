import 'dart:math' show pow;

extension StringExtensions on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${toLowerCase().substring(1)}';
  }

  num toNum() => num.parse(this);
}

extension FixedNumDecimals on double {
  String toStringFixedNumDecimals(int numDecimals) {
    return '${(this * pow(10, numDecimals)).truncate() / pow(10, numDecimals)}';
  }
}

extension NumExtensions on num {
  BigInt extractDecimals(int decimals) =>
      BigInt.parse(toStringAsFixed(decimals).replaceAll('.', ''));
}

extension BigIntExtensions on BigInt {
  num addDecimals(int decimals) {
    return getValueInUnit(this, decimals);
  }
}

double getValueInUnit(BigInt amount, int decimals) {
  final factor = BigInt.from(10).pow(decimals);
  final value = amount ~/ factor;
  final remainder = amount.remainder(factor);

  return value.toInt() + (remainder.toInt() / factor.toInt());
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

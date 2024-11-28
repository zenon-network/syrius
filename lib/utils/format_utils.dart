import 'package:flutter/services.dart';
import 'package:hex/hex.dart';
import 'package:intl/intl.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';

class FormatUtils {
  static List<TextInputFormatter> getAmountTextInputFormatters(
    String replacementString,
  ) =>
      <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*\.?\d*?$'),
          replacementString: replacementString,
        ),
        FilteringTextInputFormatter.deny(
          RegExp(r'^0\d+'),
          replacementString: replacementString,
        ),
      ];

  static List<TextInputFormatter> getPlasmaAmountTextInputFormatters(
    String replacementString,
  ) =>
      <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        FilteringTextInputFormatter.deny(
          RegExp(r'^0\d+'),
          replacementString: replacementString,
        ),
      ];

  static String encodeHexString(List<int> input) => HEX.encode(input);

  static List<int> decodeHexString(String input) => HEX.decode(input);

  static String formatDate(
    int timestampMillis, {
    String dateFormat = kDefaultDateFormat,
  }) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    return DateFormat(dateFormat).format(date);
  }

  static String extractNameFromEnum<T>(T enumValue) {
    final String valueName = enumValue.toString().split('.')[1];
    if (RegExp('^[a-z]+[A-Z]+').hasMatch(valueName)) {
      final List<String> parts = valueName
          .split(RegExp('(?<=[a-z])(?=[A-Z])'))
          .map((String e) => e.toLowerCase())
          .toList();
      parts.first = parts.first.capitalize();
      return parts.join(' ');
    }
    return valueName.capitalize();
  }

  static int subtractDaysFromDate(int numDays, DateTime referenceDate) {
    return referenceDate
        .subtract(
          Duration(
            days: kStandardChartNumDays.toInt() - 1 - numDays,
          ),
        )
        .millisecondsSinceEpoch;
  }

  static String formatData(int transactionMillis) {
    final int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(days: 1).inMilliseconds) {
      return formatDataShort(currentMillis - transactionMillis);
    }

    final DateTime now = DateTime.now();
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(
      transactionMillis,
    );
    final bool isCurrentYear = date.year == now.year;

    // Use different formats based on the year condition
    final String dateFormat = isCurrentYear
        ? 'MMM d' // Format without the year
        : 'MMM d, y'; // Format with the year
    return FormatUtils.formatDate(transactionMillis, dateFormat: dateFormat);
  }

  static String formatDataShort(int i) {
    final Duration duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ago';
    }
    return '${duration.inSeconds} s ago';
  }
}

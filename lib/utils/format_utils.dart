import 'package:flutter/services.dart';
import 'package:hex/hex.dart';
import 'package:intl/intl.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';

class FormatUtils {
  static List<TextInputFormatter> getAmountTextInputFormatters(
    String replacementString,
  ) =>
      [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*?$'),
            replacementString: replacementString),
        FilteringTextInputFormatter.deny(
          RegExp(r'^0\d+'),
          replacementString: replacementString,
        ),
      ];

  static List<TextInputFormatter> getPlasmaAmountTextInputFormatters(
    String replacementString,
  ) =>
      [
        FilteringTextInputFormatter.digitsOnly,
        FilteringTextInputFormatter.deny(
          RegExp(r'^0\d+'),
          replacementString: replacementString,
        ),
      ];

  static List<int> decodeHexString(String input) => HEX.decode(input);

  static String formatDate(int timestampMillis,
      {String dateFormat = kDefaultDateFormat}) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    return DateFormat(dateFormat).format(date);
  }

  static String extractNameFromEnum<T>(T enumValue) {
    String valueName = enumValue.toString().split('.')[1];
    if (RegExp(r'^[a-z]+[A-Z]+').hasMatch(valueName)) {
      List<String> parts = valueName
          .split(RegExp(r'(?<=[a-z])(?=[A-Z])'))
          .map((e) => e.toLowerCase())
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
    int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(days: 1).inMilliseconds) {
      return formatDataShort(currentMillis - transactionMillis);
    }
    return FormatUtils.formatDate(transactionMillis, dateFormat: 'MM/dd/yyyy');
  }

  static String formatDataShort(int i) {
    Duration duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ago';
    }
    return '${duration.inSeconds} s ago';
  }
}

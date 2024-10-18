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
            replacementString: replacementString,),
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

  static String encodeHexString(List<int> input) => HEX.encode(input);
  static List<int> decodeHexString(String input) => HEX.decode(input);

  static String formatDate(int timestampMillis,
      {String dateFormat = kDefaultDateFormat,}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    return DateFormat(dateFormat).format(date);
  }

  static String extractNameFromEnum<T>(T enumValue) {
    final valueName = enumValue.toString().split('.')[1];
    if (RegExp('^[a-z]+[A-Z]+').hasMatch(valueName)) {
      final parts = valueName
          .split(RegExp('(?<=[a-z])(?=[A-Z])'))
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
    final currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(days: 1).inMilliseconds) {
      return formatDataShort(currentMillis - transactionMillis);
    }
    return FormatUtils.formatDate(transactionMillis, dateFormat: 'MM/dd/yyyy');
  }

  static String formatDataShort(int i) {
    final duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ago';
    }
    return '${duration.inSeconds} s ago';
  }
}

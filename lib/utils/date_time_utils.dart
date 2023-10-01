class DateTimeUtils {
  static int get unixTimeNow => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

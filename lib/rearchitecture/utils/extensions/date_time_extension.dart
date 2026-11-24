/// Extension meant to enhance the [DateTime] class
extension DateTimeExtension on DateTime {
  /// Returns this date and time as a Unix timestamp in seconds.
  /// Not to be used were extreme accuracy is needed.
  int get unixTimestamp => millisecondsSinceEpoch ~/ 1000;
}

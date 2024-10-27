/// A custom exception that displays only the message when printed.
abstract class SyriusException implements Exception {
  /// Creates a [SyriusException] with a required message.
  SyriusException(this.message);
  /// The exception message
  final String message;

  /// Returns the exception message without the 'Exception:' prefix.
  @override
  String toString() => message;
}

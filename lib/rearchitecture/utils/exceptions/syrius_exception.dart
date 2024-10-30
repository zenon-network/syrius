
import 'package:equatable/equatable.dart';

/// A custom exception that displays only the message when printed.
abstract class SyriusException extends Equatable implements Exception {
  /// Creates a [SyriusException] with a required message.
  const SyriusException(this.message);

  /// The exception message
  final String message;

  /// Returns the exception message without the 'Exception:' prefix.
  @override
  String toString() => message;

  @override
  List<Object?> get props => <Object?>[message];
}

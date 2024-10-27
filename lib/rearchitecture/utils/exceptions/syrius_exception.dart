import 'package:json_annotation/json_annotation.dart';

part 'syrius_exception.g.dart';

/// A custom exception that displays only the message when printed.
@JsonSerializable()
class SyriusException implements Exception {
  /// Creates a [SyriusException] with a required message.
  SyriusException(this.message);

  /// Creates a [SyriusException] instance from a JSON map.
  factory SyriusException.fromJson(Map<String, dynamic> json) =>
      _$SyriusExceptionFromJson(json);

  /// The exception message
  final String message;

  /// Converts this [SyriusException] instance to a JSON map.
  Map<String, dynamic> toJson() => _$SyriusExceptionToJson(this);

  /// Returns the exception message without the 'Exception:' prefix.
  @override
  String toString() => message;
}

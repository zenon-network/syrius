import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'failure_exception.g.dart';

/// A class to be used as a generic exception when something unexpected goes
/// wrong.
@immutable
@JsonSerializable()
class FailureException extends SyriusException {
  /// Creates a [FailureException] instance.
  FailureException({
    String message = 'Something went wrong',
  }) : super(message);

  /// Creates a [FailureException] instance from a JSON map.
  factory FailureException.fromJson(Map<String, dynamic> json) =>
      _$FailureExceptionFromJson(json);

  /// Converts this [FailureException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() => _$FailureExceptionToJson(this)
    ..['runtimeType'] = 'FailureException';

  @override
  bool operator ==(Object other) {
    return other is FailureException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

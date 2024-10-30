import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'cubit_failure_exception.g.dart';

/// A class to be used as a generic exception when something unexpected goes
/// wrong inside a cubit.
@JsonSerializable()
class CubitFailureException extends SyriusException {
  /// Creates a [CubitFailureException] instance.
  CubitFailureException({
    String message = 'Something went wrong',
  }) : super(message);

  /// Creates a [CubitFailureException] instance from a JSON map.
  factory CubitFailureException.fromJson(Map<String, dynamic> json) =>
      _$CubitFailureExceptionFromJson(json);

  /// Converts this [CubitFailureException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() => _$CubitFailureExceptionToJson(this)
    ..['runtimeType'] = 'CubitFailureException';
}

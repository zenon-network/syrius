import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'cubit_exception.g.dart';

/// A custom exception that displays only the message when printed.
///
/// To be used to create custom exceptions in a specific case that we
/// are aware about - so that we can add a corresponding message
@JsonSerializable()
class CubitException extends SyriusException {
  /// Creates a [CubitException] with a required message.
  CubitException(super.message);

  /// Creates a [CubitException] instance from a JSON map.
  factory CubitException.fromJson(Map<String, dynamic> json) =>
      _$CubitExceptionFromJson(json);

  /// Creates a [CubitException] instance from a JSON map.
  Map<String, dynamic> toJson() => _$CubitExceptionToJson(this);
}

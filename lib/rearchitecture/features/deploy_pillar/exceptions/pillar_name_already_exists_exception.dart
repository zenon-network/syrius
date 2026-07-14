import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'pillar_name_already_exists_exception.g.dart';

/// A [SyriusException] used when there is no balance available on a specific
/// address
@immutable
@JsonSerializable()
class PillarNameAlreadyExistsException extends SyriusException {
  /// Creates a [PillarNameAlreadyExistsException] instance
  PillarNameAlreadyExistsException({
    String message = 'Pillar name already exists',
  }) : super(message);

  /// {@macro instance_from_json}
  factory PillarNameAlreadyExistsException.fromJson(
    Map<String, dynamic> json,
  ) => _$PillarNameAlreadyExistsExceptionFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$PillarNameAlreadyExistsExceptionToJson(this)
        ..['runtimeType'] = 'PillarNameAlreadyExistsException';

  @override
  bool operator ==(Object other) {
    return other is PillarNameAlreadyExistsException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

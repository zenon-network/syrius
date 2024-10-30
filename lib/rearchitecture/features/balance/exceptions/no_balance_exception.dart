import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'no_balance_exception.g.dart';

/// Custom [Exception] used when there is no balance available on a specific
/// address
@immutable
@JsonSerializable()
class NoBalanceException extends SyriusException {
  /// Creates a [NoBalanceException] instance
  NoBalanceException({
    String message = 'Empty balance on the selected address',
  }) : super(message);

  /// Creates a [NoBalanceException] instance from a JSON map.
  factory NoBalanceException.fromJson(Map<String, dynamic> json) =>
      _$NoBalanceExceptionFromJson(json);

  /// Converts this [NoBalanceException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() =>
      _$NoBalanceExceptionToJson(this)..['runtimeType'] = 'NoBalanceException';

  @override
  bool operator ==(Object other) {
    return other is NoBalanceException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

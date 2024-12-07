import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'no_blocks_available_exception.g.dart';

/// An exception to be used with [RealtimeStatisticsCubit] when there are
/// no account blocks available on the network
@immutable
@JsonSerializable()
class NoBlocksAvailableException extends SyriusException {
  /// Creates a [NoBlocksAvailableException] instance
  NoBlocksAvailableException({
    String message = 'No account blocks available',
  }) : super(message);

  /// {@macro instance_from_json}
  factory NoBlocksAvailableException.fromJson(Map<String, dynamic> json) =>
      _$NoBlocksAvailableExceptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$NoBlocksAvailableExceptionToJson(this)
    ..['runtimeType'] = 'NoBlocksAvailableException';

  @override
  bool operator ==(Object other) {
    return other is NoBlocksAvailableException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'no_active_skaking_entries_exception.g.dart';

/// An exception to be used with [StakingCubit] when there are no active
/// staking entries found on an address
@immutable
@JsonSerializable()
class NoActiveStakingEntriesException extends SyriusException {
  /// Creates a [NoActiveStakingEntriesException] instance
  NoActiveStakingEntriesException({
    String message = 'No active staking entries',
  }) : super(message);

  /// Creates a [NoActiveStakingEntriesException] instance from a JSON map.
  factory NoActiveStakingEntriesException.fromJson(Map<String, dynamic> json) =>
      _$NoActiveStakingEntriesExceptionFromJson(json);

  /// Converts this [NoActiveStakingEntriesException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() => _$NoActiveStakingEntriesExceptionToJson(this)
    ..['runtimeType'] = 'NoActiveStakingEntriesException';

  @override
  bool operator ==(Object other) {
    return other is NoActiveStakingEntriesException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

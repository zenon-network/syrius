import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

part 'no_active_skaking_entries_exception.g.dart';

/// Custom [Exception] to be used with [StakingCubit] when there are
/// no active staking entries found on an address
@JsonSerializable()
class NoActiveStakingEntriesException extends DashboardCubitException {
  /// Creates a [NoActiveStakingEntriesException] instance
  NoActiveStakingEntriesException() : super('No active staking entries');

  /// Creates a [NoActiveStakingEntriesException] instance from a JSON map.
  factory NoActiveStakingEntriesException.fromJson(Map<String, dynamic> json) =>
      _$NoActiveStakingEntriesExceptionFromJson(json);

  /// Converts this [NoActiveStakingEntriesException] instance to a JSON map.
  Map<String, dynamic> toJson() =>
      _$NoActiveStakingEntriesExceptionToJson(this);
}

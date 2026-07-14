import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'no_rewards_last_week_exception.g.dart';

/// A [SyriusException] used when there are no pillar rewards in the last week.
@immutable
@JsonSerializable()
class NoRewardsLastWeekException extends SyriusException {
  /// Creates a [NoRewardsLastWeekException] instance
  NoRewardsLastWeekException({
    String message = 'No rewards in the last week',
  }) : super(message);

  /// {@macro instance_from_json}
  factory NoRewardsLastWeekException.fromJson(
    Map<String, dynamic> json,
  ) => _$NoRewardsLastWeekExceptionFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$NoRewardsLastWeekExceptionToJson(this)
        ..['runtimeType'] = 'NoRewardsLastWeekException';

  @override
  bool operator ==(Object other) {
    return other is NoRewardsLastWeekException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

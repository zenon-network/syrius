import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'no_delegation_stats_exception.g.dart';

/// An exception used when there are no delegation info available
@immutable
@JsonSerializable()
class NoDelegationStatsException extends SyriusException {
  /// Creates a [NoDelegationStatsException] instance
  NoDelegationStatsException({
    String message = 'No delegation stats available',
  }) : super(message);

  /// Creates a [NoDelegationStatsException] instance from a JSON map.
  factory NoDelegationStatsException.fromJson(Map<String, dynamic> json) =>
      _$NoDelegationStatsExceptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$NoDelegationStatsExceptionToJson(this)
    ..['runtimeType'] = 'NoDelegationStatsException';

  @override
  bool operator ==(Object other) {
    return other is NoDelegationStatsException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'no_delegation_stats_exception.g.dart';

/// Custom [Exception] used when there are no delegation info available
@JsonSerializable()
class NoDelegationStatsException extends CubitException {
  /// Creates a [NoDelegationStatsException] instance
  NoDelegationStatsException({
    String message = 'No delegation stats available',
  }) : super(message);

  /// Creates a [NoDelegationStatsException] instance from a JSON map.
  factory NoDelegationStatsException.fromJson(Map<String, dynamic> json) =>
      _$NoDelegationStatsExceptionFromJson(json);

  @override
  bool operator ==(Object other) {
    return other is NoDelegationStatsException && other.runtimeType == runtimeType && other.message == message;
  }
}

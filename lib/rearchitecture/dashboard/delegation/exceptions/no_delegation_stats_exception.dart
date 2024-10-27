import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard_cubit_exception.dart';

part 'no_delegation_stats_exception.g.dart';

/// Custom [Exception] used when there are no delegation info available
@JsonSerializable()
class NoDelegationStatsException extends DashboardCubitException {
  /// Creates a [NoDelegationStatsException] instance
  NoDelegationStatsException(): super('No delegation stats available');

  /// Creates a [NoDelegationStatsException] instance from a JSON map.
  factory NoDelegationStatsException.fromJson(Map<String, dynamic> json) =>
      _$NoDelegationStatsExceptionFromJson(json);


  /// Converts this [NoDelegationStatsException] instance to a JSON map.
  Map<String, dynamic> toJson() => _$NoDelegationStatsExceptionToJson(this);
}

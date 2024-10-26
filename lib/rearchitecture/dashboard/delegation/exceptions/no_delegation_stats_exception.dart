import 'package:json_annotation/json_annotation.dart';

part 'no_delegation_stats_exception.g.dart';

/// Custom [Exception] used when there are no delegation info available
@JsonSerializable()
class NoDelegationStatsException implements Exception {
  /// Creates a [NoDelegationStatsException] instance
  NoDelegationStatsException();

  /// Creates a [NoDelegationStatsException] instance from a JSON map.
  factory NoDelegationStatsException.fromJson(Map<String, dynamic> json) =>
      _$NoDelegationStatsExceptionFromJson(json);


  /// Converts this [NoDelegationStatsException] instance to a JSON map.
  Map<String, dynamic> toJson() => _$NoDelegationStatsExceptionToJson(this);

  @override
  String toString() => 'No delegation stats available';
}

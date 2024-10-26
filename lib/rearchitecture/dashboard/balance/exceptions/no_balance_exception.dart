import 'package:json_annotation/json_annotation.dart';

part 'no_balance_exception.g.dart';

/// Custom [Exception] used when there is no balance available on a specific
/// address
@JsonSerializable()
class NoBalanceException implements Exception {
  /// Creates a [NoBalanceException] instance
  NoBalanceException();

  /// Creates a [NoBalanceException] instance from a JSON map.
  factory NoBalanceException.fromJson(Map<String, dynamic> json) =>
      _$NoBalanceExceptionFromJson(json);


  /// Converts this [NoBalanceException] instance to a JSON map.
  Map<String, dynamic> toJson() => _$NoBalanceExceptionToJson(this);
  @override
  String toString() => 'Empty balance on the selected address';
}

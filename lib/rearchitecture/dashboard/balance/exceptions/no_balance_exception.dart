import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

part 'no_balance_exception.g.dart';

/// Custom [Exception] used when there is no balance available on a specific
/// address
@JsonSerializable()
class NoBalanceException extends DashboardCubitException {
  /// Creates a [NoBalanceException] instance
  NoBalanceException(): super('Empty balance on the selected address');

  /// Creates a [NoBalanceException] instance from a JSON map.
  factory NoBalanceException.fromJson(Map<String, dynamic> json) =>
      _$NoBalanceExceptionFromJson(json);


  /// Converts this [NoBalanceException] instance to a JSON map.
  Map<String, dynamic> toJson() => _$NoBalanceExceptionToJson(this);
}

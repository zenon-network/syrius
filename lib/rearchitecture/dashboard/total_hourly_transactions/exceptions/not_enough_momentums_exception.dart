import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

part 'not_enough_momentums_exception.g.dart';

/// Custom [Exception] to be used with [TotalHourlyTransactionsCubit] when
/// the network is less than one hour old
@JsonSerializable()
class NotEnoughMomentumsException extends DashboardCubitException {
  /// Creates a [NotEnoughMomentumsException] instance
  NotEnoughMomentumsException(): super('Not enough momentums');

  /// Creates a [NotEnoughMomentumsException] instance from a JSON map.
  factory NotEnoughMomentumsException.fromJson(Map<String, dynamic> json) =>
      _$NotEnoughMomentumsExceptionFromJson(json);


  /// Converts this [NotEnoughMomentumsException] instance to a JSON map.
  Map<String, dynamic> toJson() => _$NotEnoughMomentumsExceptionToJson(this);
}

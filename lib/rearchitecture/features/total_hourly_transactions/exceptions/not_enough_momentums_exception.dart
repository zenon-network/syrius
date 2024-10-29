import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'not_enough_momentums_exception.g.dart';

/// Custom [Exception] to be used with [TotalHourlyTransactionsCubit] when
/// the network is less than one hour old
@JsonSerializable()
class NotEnoughMomentumsException extends CubitException {
  /// Creates a [NotEnoughMomentumsException] instance
  NotEnoughMomentumsException({
    String message = 'Not enough momentums',
  }) : super(message);

  /// Creates a [NotEnoughMomentumsException] instance from a JSON map.
  factory NotEnoughMomentumsException.fromJson(Map<String, dynamic> json) =>
      _$NotEnoughMomentumsExceptionFromJson(json);

  /// Converts this [NotEnoughMomentumsException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() => _$NotEnoughMomentumsExceptionToJson(this);
}

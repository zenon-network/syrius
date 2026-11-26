import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'not_enough_momentums_exception.g.dart';

const String _kDefaultMessage = 'Not enough momentums';

/// Custom [Exception] to be used with [TotalHourlyTransactionsCubit] when
/// the network is less than one hour old
@immutable
@JsonSerializable()
class NotEnoughMomentumsException extends SyriusException {
  /// Creates a [NotEnoughMomentumsException] instance.
  NotEnoughMomentumsException({String message = _kDefaultMessage})
    : super(message);

  /// {@macro instance_from_json}
  factory NotEnoughMomentumsException.fromJson(Map<String, dynamic> json) =>
      _$NotEnoughMomentumsExceptionFromJson(json);

  @override
  String localizedMessage(AppLocalizations l10n) =>
      message == _kDefaultMessage ? l10n.notEnoughMomentums : message;

  @override
  Map<String, dynamic> toJson() =>
      _$NotEnoughMomentumsExceptionToJson(this)
        ..['runtimeType'] = 'NotEnoughMomentumsException';

  @override
  bool operator ==(Object other) {
    return other is NotEnoughMomentumsException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'no_balance_exception.g.dart';

const String _kDefaultMessage = 'Empty balance on the selected address';

/// A [SyriusException] used when there is no balance available on a specific
/// address
@immutable
@JsonSerializable()
class NoBalanceException extends SyriusException {
  /// Creates a [NoBalanceException] instance
  NoBalanceException({String message = _kDefaultMessage}) : super(message);

  /// {@macro instance_from_json}
  factory NoBalanceException.fromJson(Map<String, dynamic> json) =>
      _$NoBalanceExceptionFromJson(json);

  @override
  String localizedMessage(AppLocalizations l10n) => message == _kDefaultMessage
      ? l10n.emptyBalanceOnSelectedAddress
      : message;

  @override
  Map<String, dynamic> toJson() =>
      _$NoBalanceExceptionToJson(this)..['runtimeType'] = 'NoBalanceException';

  @override
  bool operator ==(Object other) {
    return other is NoBalanceException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

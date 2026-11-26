import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'failure_exception.g.dart';

const String _kDefaultMessage = 'Something went wrong';

/// A class to be used as a generic exception when something unexpected goes
/// wrong.
@immutable
@JsonSerializable()
class FailureException extends SyriusException {
  /// Creates a [FailureException] instance.
  FailureException({String message = _kDefaultMessage}) : super(message);

  /// Creates a [FailureException] instance from a JSON map.
  factory FailureException.fromJson(Map<String, dynamic> json) =>
      _$FailureExceptionFromJson(json);

  @override
  String localizedMessage(AppLocalizations l10n) =>
      message == _kDefaultMessage ? l10n.somethingWentWrong : message;

  /// Converts this [FailureException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() =>
      _$FailureExceptionToJson(this)..['runtimeType'] = 'FailureException';

  @override
  bool operator ==(Object other) {
    return other is FailureException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'no_delegation_stats_exception.g.dart';

const String _kDefaultMessage = 'No delegation stats available';

/// An exception used when there are no delegation stats info available
@immutable
@JsonSerializable()
class NoDelegationStatsException extends SyriusException {
  /// Creates a [NoDelegationStatsException] instance
  NoDelegationStatsException({String message = _kDefaultMessage})
    : super(message);

  /// {@macro instance_from_json}
  factory NoDelegationStatsException.fromJson(Map<String, dynamic> json) =>
      _$NoDelegationStatsExceptionFromJson(json);

  @override
  String localizedMessage(AppLocalizations l10n) =>
      message == _kDefaultMessage ? l10n.noDelegationStatsAvailable : message;

  @override
  Map<String, dynamic> toJson() =>
      _$NoDelegationStatsExceptionToJson(this)
        ..['runtimeType'] = 'NoDelegationStatsException';

  @override
  bool operator ==(Object other) {
    return other is NoDelegationStatsException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

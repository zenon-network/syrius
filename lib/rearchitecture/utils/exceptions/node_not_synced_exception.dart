import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'node_not_synced_exception.g.dart';

const String _kDefaultMessage = 'Node is not synced';

/// An exception to be throw when the node is not synced
@immutable
@JsonSerializable()
class NodeNotSyncedException extends SyriusException {
  /// Creates a [NodeNotSyncedException] instance.
  NodeNotSyncedException({String message = _kDefaultMessage}) : super(message);

  /// Creates a [NodeNotSyncedException] instance from a JSON map.
  factory NodeNotSyncedException.fromJson(Map<String, dynamic> json) =>
      _$NodeNotSyncedExceptionFromJson(json);

  @override
  String localizedMessage(AppLocalizations l10n) =>
      message == _kDefaultMessage ? l10n.nodeNotSynced : message;

  /// Converts this [NodeNotSyncedException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() =>
      _$NodeNotSyncedExceptionToJson(this)
        ..['runtimeType'] = 'NodeNotSyncedException';

  @override
  bool operator ==(Object other) {
    return other is NodeNotSyncedException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

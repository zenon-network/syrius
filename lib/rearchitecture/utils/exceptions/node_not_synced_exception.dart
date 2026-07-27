import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'node_not_synced_exception.g.dart';

/// An exception to be throw when the node is not synced
@immutable
@JsonSerializable()
class NodeNotSyncedException extends SyriusException {
  /// Creates a [NodeNotSyncedException] instance.
  NodeNotSyncedException({
    String message = 'Node is not synced',
  }) : super(message);

  /// Creates a [NodeNotSyncedException] instance from a JSON map.
  factory NodeNotSyncedException.fromJson(Map<String, dynamic> json) =>
      _$NodeNotSyncedExceptionFromJson(json);

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

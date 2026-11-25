import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'empty_account_chain_exception.g.dart';

/// An exception thrown when an address has no blocks on its account-chain.
@immutable
@JsonSerializable()
class EmptyAccountChainException extends SyriusException {
  /// Creates an [EmptyAccountChainException] instance.
  EmptyAccountChainException({String message = 'Empty account-chain'})
    : super(message);

  /// Creates an [EmptyAccountChainException] from JSON.
  factory EmptyAccountChainException.fromJson(Map<String, dynamic> json) =>
      _$EmptyAccountChainExceptionFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$EmptyAccountChainExceptionToJson(this)
        ..['runtimeType'] = 'EmptyAccountChainException';

  @override
  bool operator ==(Object other) {
    return other is EmptyAccountChainException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

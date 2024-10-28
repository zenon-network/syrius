import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

part 'no_blocks_available_exception.g.dart';

/// Custom [Exception] to be used with [RealtimeStatisticsCubit] when there are
/// no account blocks available on the network
@JsonSerializable()
class NoBlocksAvailableException extends CubitException {
  /// Creates a [NoBlocksAvailableException] instance
  NoBlocksAvailableException(): super('No account blocks available');

  /// Creates a [NoBlocksAvailableException] instance from a JSON map.
  factory NoBlocksAvailableException.fromJson(Map<String, dynamic> json) =>
      _$NoBlocksAvailableExceptionFromJson(json);


  /// Converts this [NoBlocksAvailableException] instance to a JSON map.
  @override
  Map<String, dynamic> toJson() => _$NoBlocksAvailableExceptionToJson(this);
}

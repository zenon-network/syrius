import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

/// A custom exception that displays only the message when printed.
class SyriusException implements Exception {
  /// Creates a [SyriusException] with a required message.
  SyriusException(this.message);

  /// Factory constructor for creating a new instance from a map.
  factory SyriusException.fromJson(Map<String, dynamic> json) {
    final String? type = json['runtimeType'] as String?;
    if (type != null) {
      switch (type) {
        case 'NoActiveStakingEntriesException':
          return NoActiveStakingEntriesException.fromJson(json);
        case 'NoBalanceException':
          return NoBalanceException.fromJson(json);
        case 'NoBlocksAvailableException':
          return NoBlocksAvailableException.fromJson(json);
        case 'FailureException':
          return FailureException.fromJson(json);
        case 'NoDelegationStatsException':
          return NoDelegationStatsException.fromJson(json);
        case 'NotEnoughMomentumsException':
          return NotEnoughMomentumsException.fromJson(json);
        default:
          throw UnsupportedError('Unknown subclass: $type');
      }
    }
    return SyriusException(json['message'] as String);
  }
  /// The exception message
  final String message;

  /// Returns the exception message without the 'Exception:' prefix.
  @override
  String toString() => message;

  /// Method to convert the object into a map with a type identifier.
  Map<String, dynamic> toJson() => <String, dynamic>{'message': message};
}

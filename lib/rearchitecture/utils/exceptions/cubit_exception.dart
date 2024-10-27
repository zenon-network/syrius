import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// A custom exception that displays only the message when printed.
///
/// To be used to create custom exceptions in a specific case that we
/// are aware about - so that we can add a corresponding message
abstract class CubitException extends SyriusException {
  /// Creates a [CubitException] with a required message.
  CubitException(super.message);
}

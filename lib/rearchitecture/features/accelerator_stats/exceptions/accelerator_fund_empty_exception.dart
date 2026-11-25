import 'package:flutter/foundation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

/// Exception thrown when the Accelerator embedded contract holds no ZNN or QSR.
@immutable
class AcceleratorFundEmptyException extends SyriusException {
  /// Creates an [AcceleratorFundEmptyException].
  AcceleratorFundEmptyException([super.message = 'Accelerator fund empty']);

  @override
  bool operator ==(Object other) {
    return other is AcceleratorFundEmptyException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

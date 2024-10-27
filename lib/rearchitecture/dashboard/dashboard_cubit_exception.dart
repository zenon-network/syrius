import 'package:zenon_syrius_wallet_flutter/utils/exceptions/exceptions.dart';

/// A custom exception that displays only the message when printed.
///
/// To be used to create custom exceptions in a specific case that we
/// are aware about - so that we can add a corresponding message
abstract class DashboardCubitException extends SyriusException {
  /// Creates a [DashboardCubitException] with a required message.
  DashboardCubitException(super.message);
}

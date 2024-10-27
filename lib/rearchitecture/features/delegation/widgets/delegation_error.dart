import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

/// A widget that display the [error] message
class DelegationError extends StatelessWidget {
  /// Creates a DelegationError object.
  const DelegationError({required this.error, super.key});
  /// The object that holds the representation of the error
  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

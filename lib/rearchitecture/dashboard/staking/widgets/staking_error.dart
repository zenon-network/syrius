import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

/// A widget associated with the [StakingState] when it's status is
/// [CubitStatus.error] that uses the [SyriusErrorWidget] to display the error.
class StakingError extends StatelessWidget {
  /// Creates a StakingError object.
  const StakingError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

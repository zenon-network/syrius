import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

/// A widget associated with the [DualCoinStatsState] when it's status is
/// [CubitStatus.failure] that uses the [SyriusErrorWidget] to display the
/// error message

class DualCoinStatsError extends StatelessWidget {

  const DualCoinStatsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget associated with the [PillarsState] when it's status is
/// [DashboardStatus.failure] that uses the [SyriusErrorWidget] to display the
/// error message
class PillarsError extends StatelessWidget {
  ///Creates a PillarsError object
  const PillarsError({required this.error, super.key});
  /// Holds the data that will be displayed
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

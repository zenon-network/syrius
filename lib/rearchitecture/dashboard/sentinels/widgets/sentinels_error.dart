import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [SentinelsState] when it's status is
/// [DashboardStatus.failure] that uses the [SyriusErrorWidget] to display an
/// error.
class SentinelsError extends StatelessWidget {
  /// Creates a SentinelsError objects.
  const SentinelsError({required this.error, super.key});
  /// The object that holds the representation of the error
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

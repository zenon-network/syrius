import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [SentinelsState] when it's status is
/// [CubitStatus.loading] that uses the [SyriusErrorWidget] to display a message
class SentinelsLoading extends StatelessWidget {
  /// Creates a SentinelsLoading object.
  const SentinelsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}

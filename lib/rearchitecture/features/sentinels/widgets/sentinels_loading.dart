import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [SentinelsState] when it's status is
/// [TimerStatus.loading] that uses the [SyriusLoadingWidget] to display a
/// loading indicator.
class SentinelsLoading extends StatelessWidget {
  /// Creates a SentinelsLoading object.
  const SentinelsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [ActiveSentinelsState] when its status is
/// [TimerStatus.loading] that uses the [SyriusLoadingWidget] to display a
/// loading indicator.
class ActiveSentinelsLoading extends StatelessWidget {
  /// Creates an [ActiveSentinelsLoading].
  const ActiveSentinelsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}

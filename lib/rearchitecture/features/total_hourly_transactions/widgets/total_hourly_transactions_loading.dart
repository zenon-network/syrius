import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A widget associated with the [TotalHourlyTransactionsState] when it's
/// status is [TimerStatus.loading] that uses the [SyriusLoadingWidget] to
/// display a loading indicator.
class TotalHourlyTransactionsLoading extends StatelessWidget {
  /// Creates a TotalHourlyTransactionsLoading object.
  const TotalHourlyTransactionsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
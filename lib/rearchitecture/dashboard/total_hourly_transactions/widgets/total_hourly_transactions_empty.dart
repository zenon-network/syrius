import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [TotalHourlyTransactionsState] when it's
/// status is [CubitStatus.initial] that uses the [SyriusErrorWidget] to
/// display a message
class TotalHourlyTransactionsEmpty extends StatelessWidget {
  /// Creates a TotalHourlyTransactionsEmpty object.
  const TotalHourlyTransactionsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusErrorWidget('No data available');
  }
}

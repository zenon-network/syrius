import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

/// A widget associated with the [TotalHourlyTransactionsState] when it's
/// status is [DashboardStatus.failure] that uses the [SyriusErrorWidget] to
/// display the error.
class TotalHourlyTransactionsError extends StatelessWidget {
  /// Creates a TotalHourlyTransactionError object.
  const TotalHourlyTransactionsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

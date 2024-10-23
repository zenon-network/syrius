import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';

/// A widget connected to the [TotalHourlyTransactionsCubit] that receives the
/// state - [TotalHourlyTransactionsState] - updates and rebuilds the UI
/// according to the state's status - [CubitStatus]
class TotalHourlyTransactionsCard extends StatelessWidget {
  /// Creates a TotalHourlyTransactionsCard object.
  const TotalHourlyTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = TotalHourlyTransactionsCubit(
          zenon!,
          const TotalHourlyTransactionsState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.totalHourlyTransactions.getData(context: context),
        body: BlocBuilder<TotalHourlyTransactionsCubit,
            TotalHourlyTransactionsState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const TotalHourlyTransactionsEmpty(),
              CubitStatus.loading => const TotalHourlyTransactionsLoading(),
              CubitStatus.failure => TotalHourlyTransactionsError(
                  error: state.error!,
                ),
              CubitStatus.success => TotalHourlyTransactionsPopulated(
                  count: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

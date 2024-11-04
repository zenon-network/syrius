import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// A widget connected to the [TotalHourlyTransactionsCubit] that receives the
/// state - [TotalHourlyTransactionsState] - updates and rebuilds the UI
/// according to the state's status - [TimerStatus].
class TotalHourlyTransactionsCard extends StatelessWidget {
  /// Creates a TotalHourlyTransactionsCard object.
  const TotalHourlyTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TotalHourlyTransactionsCubit>(
      create: (_) => TotalHourlyTransactionsCubit(
        zenon: zenon!,
      )..fetchDataPeriodically(),
      child: NewCardScaffold(
        data: CardType.totalHourlyTransactions.getData(context: context),
        body: BlocBuilder<TotalHourlyTransactionsCubit,
            TotalHourlyTransactionsState>(
          builder: (BuildContext context, TotalHourlyTransactionsState state) {
            return switch (state.status) {
              TimerStatus.initial => const TotalHourlyTransactionsEmpty(),
              TimerStatus.loading => const TotalHourlyTransactionsLoading(),
              TimerStatus.failure => TotalHourlyTransactionsError(
                  error: state.error!,
                ),
              TimerStatus.success => TotalHourlyTransactionsPopulated(
                  count: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

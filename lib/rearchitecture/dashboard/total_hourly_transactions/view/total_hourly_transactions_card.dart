import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

class TotalHourlyTransactionsCard extends StatelessWidget {
  const TotalHourlyTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = TotalHourlyTransactionsCubit(
          zenon!,
          const TotalHourlyTransactionsState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<TotalHourlyTransactionsCubit, DashboardState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const TotalHourlyTransactionsEmpty(),
              CubitStatus.loading => const TotalHourlyTransactionsLoading(),
              CubitStatus.failure => TotalHourlyTransactionsError(
                  error: state.error!,
                ),
              CubitStatus.success => TotalHourlyTransactionsPopulated(
                  data: state.data,
                ),
            };
          },
        ),
      ),
    );
  }
}

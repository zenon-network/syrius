import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';


class DualCoinStatsCard extends StatelessWidget {
  const DualCoinStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final DualCoinStatsCubit cubit = DualCoinStatsCubit(
          zenon!,
          DualCoinStatsState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<DualCoinStatsCubit, DashboardState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const DualCoinStatsEmpty(),
              CubitStatus.loading => const DualCoinStatsLoading(),
              CubitStatus.failure => DualCoinStatsError(
                  error: state.error!,
                ),
              CubitStatus.success => DualCoinStatsPopulated(
                  data: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

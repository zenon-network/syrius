import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';



class RealtimeStatisticsCard extends StatelessWidget {
  const RealtimeStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = RealtimeStatisticsCubit(
          zenon!,
          const RealtimeStatisticsState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<RealtimeStatisticsCubit, DashboardState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const RealtimeStatisticsEmpty(),
              CubitStatus.loading => const RealtimeStatisticsLoading(),
              CubitStatus.failure => RealtimeStatisticsError(
                  error: state.error!,
                ),
              CubitStatus.success => RealtimeStatisticsPopulated(
                  data: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

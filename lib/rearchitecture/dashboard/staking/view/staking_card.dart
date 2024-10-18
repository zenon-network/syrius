import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

class StakingCard extends StatelessWidget {
  const StakingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = StakingCubit(
          zenon!,
          const StakingState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<StakingCubit, DashboardState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const StakingEmpty(),
              CubitStatus.loading => const StakingLoading(),
              CubitStatus.failure => StakingError(
                  error: state.error!,
                ),
              CubitStatus.success => StakingPopulated(
                  data: state.data,
                ),
            };
          },
        ),
      ),
    );
  }
}

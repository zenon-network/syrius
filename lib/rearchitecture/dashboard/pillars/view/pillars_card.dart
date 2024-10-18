import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';


class PillarsCard extends StatelessWidget {
  const PillarsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PillarsCubit(
          zenon!,
          const PillarsState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<PillarsCubit, DashboardState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const PillarsEmpty(),
              CubitStatus.loading => const PillarsLoading(),
              CubitStatus.failure => PillarsError(
                  error: state.error!,
                ),
              CubitStatus.success => PillarsPopulated(
                  data: state.data,
                ),
            };
          },
        ),
      ),
    );
  }
}

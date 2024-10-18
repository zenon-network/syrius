import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

class SentinelsCard extends StatelessWidget {
  const SentinelsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = SentinelsCubit(
          zenon!,
          const SentinelsState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<SentinelsCubit, DashboardState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const SentinelsEmpty(),
              CubitStatus.loading => const SentinelsLoading(),
              CubitStatus.failure => SentinelsError(
                  error: state.error!,
                ),
              CubitStatus.success => SentinelsPopulated(
                  data: state.data,
                ),
            };
          },
        ),
      ),
    );
  }
}

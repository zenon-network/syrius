import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';

class RealtimeStatisticsCard extends StatelessWidget {
  const RealtimeStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = RealtimeStatisticsCubit(
          zenon!,
          const RealtimeStatisticsState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.realtimeStatistics.getData(context: context),
        body: BlocBuilder<RealtimeStatisticsCubit, RealtimeStatisticsState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const RealtimeStatisticsEmpty(),
              CubitStatus.loading => const RealtimeStatisticsLoading(),
              CubitStatus.failure => RealtimeStatisticsError(
                  error: state.error!,
                ),
              CubitStatus.success => RealtimeStatisticsPopulated(
                  accountBlocks: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

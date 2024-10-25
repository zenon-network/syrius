import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';

/// A card that receives [RealtimeStatisticsState] updates from the
/// [RealtimeStatisticsCubit] and changes the UI according to the request
/// status - [DashboardStatus]
class RealtimeStatisticsCard extends StatelessWidget {
  /// Creates a RealtimeStatisticsCard object.
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
              DashboardStatus.initial => const RealtimeStatisticsEmpty(),
              DashboardStatus.loading => const RealtimeStatisticsLoading(),
              DashboardStatus.failure => RealtimeStatisticsError(
                  error: state.error!,
                ),
              DashboardStatus.success => RealtimeStatisticsPopulated(
                  accountBlocks: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

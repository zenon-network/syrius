import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// A card that receives [RealtimeStatisticsState] updates from the
/// [RealtimeStatisticsCubit] and changes the UI according to the request
/// status - [TimerStatus]
class RealtimeStatisticsCard extends StatelessWidget {
  /// Creates a RealtimeStatisticsCard object.
  const RealtimeStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RealtimeStatisticsCubit>(
      create: (_) {
        final RealtimeStatisticsCubit cubit = RealtimeStatisticsCubit(
          zenon: zenon!,
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.realtimeStatistics.getData(context: context),
        body: BlocBuilder<RealtimeStatisticsCubit, RealtimeStatisticsState>(
          builder: (BuildContext context, RealtimeStatisticsState state) {
            return switch (state.status) {
              TimerStatus.initial => const RealtimeStatisticsEmpty(),
              TimerStatus.loading => const RealtimeStatisticsLoading(),
              TimerStatus.failure => RealtimeStatisticsError(
                  error: state.error!,
                ),
              TimerStatus.success => RealtimeStatisticsPopulated(
                  accountBlocks: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

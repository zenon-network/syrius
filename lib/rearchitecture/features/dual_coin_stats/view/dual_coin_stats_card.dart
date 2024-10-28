import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';


/// Widget connected to the [DualCoinStatsCubit] that receives the state
/// - [DualCoinStatsState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus]
class DualCoinStatsCard extends StatelessWidget {

  /// Create a DualCoinStatsCard.
  const DualCoinStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final DualCoinStatsCubit cubit = DualCoinStatsCubit(
          zenon!,
          const DualCoinStatsState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.dualCoinStats.getData(context: context),
        body: BlocBuilder<DualCoinStatsCubit, DualCoinStatsState>(
          builder: (BuildContext context, DualCoinStatsState state) {
            return switch (state.status) {
              TimerStatus.initial => const DualCoinStatsEmpty(),
              TimerStatus.loading => const DualCoinStatsLoading(),
              TimerStatus.failure => DualCoinStatsError(
                  error: state.error!,
                ),
              TimerStatus.success => DualCoinStatsPopulated(
                  tokens: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

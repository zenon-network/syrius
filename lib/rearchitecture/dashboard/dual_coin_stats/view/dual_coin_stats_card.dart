import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';


/// Widget connected to the [DualCoinStatsCubit] that receives the state
/// - [DualCoinStatsState] - updates and rebuilds the UI according to the
/// state's status - [CubitStatus]
class DualCoinStatsCard extends StatelessWidget {

  /// Create a DualCoinStatsCard.
  const DualCoinStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = DualCoinStatsCubit(
          zenon!,
          const DualCoinStatsState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.dualCoinStats.getData(context: context),
        body: BlocBuilder<DualCoinStatsCubit, DualCoinStatsState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const DualCoinStatsEmpty(),
              CubitStatus.loading => const DualCoinStatsLoading(),
              CubitStatus.failure => DualCoinStatsError(
                  error: state.error!,
                ),
              CubitStatus.success => DualCoinStatsPopulated(
                  tokens: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

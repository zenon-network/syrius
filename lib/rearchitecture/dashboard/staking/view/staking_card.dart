import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';

/// A widget connected to the [StakingCubit] that receives the state
/// - [StakingState] - updates and rebuilds the UI according to the
/// state's status - [DashboardStatus]
class StakingCard extends StatelessWidget {
  /// Creates a StakingCard object.
  const StakingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = StakingCubit(
          zenon!,
          const StakingState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.staking.getData(context: context),
        body: BlocBuilder<StakingCubit, StakingState>(
          builder: (context, state) {
            return switch (state.status) {
              DashboardStatus.initial => const StakingEmpty(),
              DashboardStatus.loading => const StakingLoading(),
              DashboardStatus.failure => StakingError(
                  error: state.error!,
                ),
              DashboardStatus.success => StakingPopulated(
                  stakingList: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

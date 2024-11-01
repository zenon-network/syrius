import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget connected to the [StakingCubit] that receives the state
/// - [StakingState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus]
class StakingCard extends StatelessWidget {
  /// Creates a StakingCard object.
  const StakingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StakingCubit>(
      create: (_) => StakingCubit(
        address: Address.parse(kSelectedAddress!),
        zenon: zenon!,
      )..fetchDataPeriodically(),
      child: NewCardScaffold(
        data: CardType.staking.getData(context: context),
        body: BlocBuilder<StakingCubit, StakingState>(
          builder: (BuildContext context, StakingState state) {
            return switch (state.status) {
              TimerStatus.initial => const StakingEmpty(),
              TimerStatus.loading => const StakingLoading(),
              TimerStatus.failure => StakingError(
                  error: state.error!,
                ),
              TimerStatus.success => StakingPopulated(
                  stakingList: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

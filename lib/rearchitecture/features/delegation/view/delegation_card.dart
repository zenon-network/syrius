import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that receives [DelegationState] updates from the [DelegationCubit]
/// and changes the UI according to the request status - [TimerStatus]
class DelegationCard extends StatelessWidget {
  /// Creates a DelegationCard object.
  const DelegationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DelegationCubit>(
      create: (_) => DelegationCubit(
        address: Address.parse(kSelectedAddress!),
        zenon: zenon!,
      )..fetchDataPeriodically(),
      child: NewCardScaffold(
        data: CardType.delegationStats.getData(context: context),
        body: BlocBuilder<DelegationCubit, DelegationState>(
          builder: (BuildContext context, DelegationState state) {
            return switch (state.status) {
              TimerStatus.initial => const DelegationEmpty(),
              TimerStatus.loading => const DelegationLoading(),
              TimerStatus.failure => DelegationError(
                  error: state.error!,
                ),
              TimerStatus.success => DelegationPopulated(
                  delegationInfo: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}

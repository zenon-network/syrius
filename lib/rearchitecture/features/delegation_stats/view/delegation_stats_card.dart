import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that receives [DelegationStatsState] updates from the [DelegationStatsCubit]
/// and changes the UI according to the request status - [TimerStatus]
class DelegationCard extends StatelessWidget {
  /// Creates a DelegationCard object.
  const DelegationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UndelegateBloc>(
          create: (_) => UndelegateBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
      ],
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: BlocBuilder<DelegationStatsCubit, DelegationStatsState>(
          builder: (BuildContext context, DelegationStatsState state) {
            return switch (state.status) {
              TimerStatus.initial => const DelegationStatsEmpty(),
              TimerStatus.loading => const DelegationStatsLoading(),
              TimerStatus.failure => DelegationStatsError(
                error: state.error!,
              ),
              TimerStatus.success => DelegationStatsPopulated(
                delegationInfo: state.data!,
              ),
            };
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.delegationStats,
    description: context.l10n.delegationStatsDescription(kZnnCoin.symbol),
  );
}

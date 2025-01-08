import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the pillar rewards
///
/// It receives updates from a [PillarRewardsHistoryCubit] and displays a
/// [PillarRewardsChart] when data is available
class PillarRewardsCard extends StatelessWidget {
  /// Constructs a new instance.
  const PillarRewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () async {
        await context.read<PillarRewardsHistoryCubit>().updateStream(
          address: Address.parse(kSelectedAddress!),
        );
      },
      body: BlocBuilder<PillarRewardsHistoryCubit, PillarRewardsHistoryState>(
        builder: (_, PillarRewardsHistoryState state) {
          final CubitWithRefreshOptionStatus status = state.status;

          return switch (status) {
            CubitWithRefreshOptionStatus.failure => SyriusErrorWidget(
              state.error!,
            ),
            CubitWithRefreshOptionStatus.loading =>
            const SyriusLoadingWidget(),
            CubitWithRefreshOptionStatus.success => PillarRewardsChart(
              rewardsHistoryList: state.data!,
            ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
        description: context.l10n.pillarRewardsDescription,
        title: context.l10n.pillarRewardsTitle,
      );
}

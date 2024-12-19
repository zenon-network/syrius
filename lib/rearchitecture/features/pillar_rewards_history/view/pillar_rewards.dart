import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the pillar rewards
///
/// It receives updates from a [PillarRewardsHistoryCubit] and displays a
/// [PillarRewardsChart] when data is available
class PillarRewardsCard extends StatefulWidget {
  /// Constructs a new instance.
  const PillarRewardsCard({super.key});

  @override
  State createState() => _PillarRewardsCardState();
}

class _PillarRewardsCardState extends State<PillarRewardsCard> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<PillarRewardsHistoryCubit>(
      create: (_) => PillarRewardsHistoryCubit(
        address: Address.parse(kSelectedAddress!),
        zenon: zenon!,
      ),
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: BlocBuilder<PillarRewardsHistoryCubit, PillarRewardsHistoryState>(
          builder: (_, PillarRewardsHistoryState state) {
            final CubitWithRefreshMixinStatus status = state.status;

            return switch (status) {
              CubitWithRefreshMixinStatus.failure => SyriusErrorWidget(
                  state.error!,
                ),
              CubitWithRefreshMixinStatus.loading =>
                const SyriusLoadingWidget(),
              CubitWithRefreshMixinStatus.success => PillarRewardsChart(
                  rewardsHistoryList: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
        description: context.l10n.pillarRewardsDescription,
        title: context.l10n.pillarRewardsTitle,
      );
}

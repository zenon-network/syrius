import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/account_chain_stats/account_chain_stats.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays account-chain height, block type breakdown, and first block hash
/// for the currently selected address.
class AccountChainStatsCard extends StatelessWidget {
  /// Creates an [AccountChainStatsCard].
  const AccountChainStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      isRefreshLoading: context
          .read<AccountChainStatsBloc>()
          .isLoadingListenable,
      onRefreshPressed: () {
        final String? selectedAddress = kSelectedAddress;
        if (selectedAddress == null) {
          return;
        }
        context.read<AccountChainStatsBloc>().add(
          FetchRequestData(address: Address.parse(selectedAddress)),
        );
      },
      body: BlocBuilder<AccountChainStatsBloc, FetchState<AccountChainStats>>(
        builder: (BuildContext context, FetchState<AccountChainStats> state) {
          return switch (state) {
            FetchInitial<AccountChainStats>() => const SyriusLoadingWidget(),
            FetchFailure<AccountChainStats>(:final SyriusException exception) =>
              SyriusErrorWidget(
                exception is EmptyAccountChainException
                    ? context.l10n.emptyAccountChain
                    : exception,
              ),
            FetchPopulated<AccountChainStats>(:final AccountChainStats data) =>
              _Populated(stats: data),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.accountChainStats,
    description: context.l10n.displaysAccountChainInformation,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({required this._stats});

  final AccountChainStats _stats;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: <Widget>[
                Text(
                  context.l10n.accountChainHeight,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    NumberAnimation(
                      end: _stats.blockCount,
                      isInt: true,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    _buildChart(),
                  ],
                ),
                _buildChartLegend(context),
                _buildExplorerButton(context),
                _buildHashMarquee(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      width: 150,
      height: 150,
      margin: const EdgeInsets.all(10),
      child: StandardPieChart(sections: _buildChartSections()),
    );
  }

  List<PieChartSectionData> _buildChartSections() =>
      BlockTypeEnum.values.map(_buildChartSection).toList();

  PieChartSectionData _buildChartSection(BlockTypeEnum blockType) {
    final int blockTypeCount = _stats.blockTypeNumOfBlocksMap[blockType] ?? 0;
    final double percentage = _stats.blockCount > 0
        ? 100.0 * blockTypeCount / _stats.blockCount
        : 0;

    return PieChartSectionData(
      showTitle: false,
      radius: 7,
      color: kBlockTypeColorMap[blockType] ?? AppColors.errorColor,
      value: percentage,
    );
  }

  Widget _buildChartLegend(BuildContext context) {
    final List<BlockTypeEnum> typesWithBlocks = _stats
        .blockTypeNumOfBlocksMap
        .keys
        .where(
          (BlockTypeEnum key) => (_stats.blockTypeNumOfBlocksMap[key] ?? 0) > 0,
        )
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: typesWithBlocks.length,
      itemBuilder: (BuildContext context, int index) {
        final BlockTypeEnum blockType = typesWithBlocks[index];
        return _buildBlockTypeCountDetails(
          context,
          blockType,
          _stats.blockTypeNumOfBlocksMap[blockType] ?? 0,
        );
      },
    );
  }

  Widget _buildBlockTypeCountDetails(
    BuildContext context,
    BlockTypeEnum blockType,
    int blockTypeCount,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '● ',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: kBlockTypeColorMap[blockType] ?? AppColors.errorColor,
            ),
          ),
          AutoSizeText(
            FormatUtils.extractNameFromEnum<BlockTypeEnum>(blockType),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 10),
          AutoSizeText(
            blockTypeCount.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExplorerButton(BuildContext context) {
    return RawMaterialButton(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () {
        unawaited(
          NavigationUtils.openUrl('$kExplorer/transaction/${_stats.firstHash}'),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.l10n.blockHash,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 10),
          const Icon(
            MaterialCommunityIcons.compass,
            size: 20,
            color: AppColors.qsrColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHashMarquee(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 12, right: 22, left: 22),
            child: Marquee(
              child: Text(
                _stats.firstHash.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

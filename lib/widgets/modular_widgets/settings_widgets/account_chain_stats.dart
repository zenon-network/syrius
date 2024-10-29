import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AccountChainStatsWidget extends StatefulWidget {

  const AccountChainStatsWidget({
    required this.accountChainStatsBloc,
    super.key,
  });
  final AccountChainStatsBloc accountChainStatsBloc;

  @override
  State createState() {
    return _AccountChainStatsState();
  }
}

class _AccountChainStatsState extends State<AccountChainStatsWidget> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Account-chain Stats',
      description: 'This card displays information regarding the account-chain '
          'for the specified address',
      childBuilder: _getStreamBuilder,
    );
  }

  Widget _getBody(AccountChainStats stats) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: <Widget>[
                Text(
                  'Account-chain height',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    NumberAnimation(
                      end: stats.blockCount,
                      isInt: true,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    _getChart(stats),
                  ],
                ),
                _getChartLegend(stats),
                RawMaterialButton(
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => NavigationUtils.openUrl(
                    '$kExplorer/transaction/${stats.firstHash}',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Block hash',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Container(width: 10),
                      const Icon(
                        MaterialCommunityIcons.compass,
                        size: 20,
                        color: AppColors.qsrColor,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(
                          top: 12,
                          right: 22,
                          left: 22,
                        ),
                        child: Marquee(
                          child: Text(
                            stats.firstHash.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _getChart(AccountChainStats stats) {
    return Container(
      width: 150,
      height: 150,
      margin: const EdgeInsets.all(
        10,
      ),
      child: StandardPieChart(
        sections: _getChartSections(stats),
      ),
    );
  }

  PieChartSectionData _getChartSection(
    AccountChainStats stats,
    BlockTypeEnum blockType,
  ) {
    final int blockTypeCount = stats.blockTypeNumOfBlocksMap[blockType]!;

    return PieChartSectionData(
      showTitle: false,
      radius: 7,
      color: kBlockTypeColorMap[blockType] ?? AppColors.errorColor,
      value: 100.0 * blockTypeCount / stats.blockCount,
    );
  }

  Widget _getStreamBuilder() {
    return StreamBuilder<AccountChainStats?>(
      stream: widget.accountChainStatsBloc.stream,
      builder: (_, AsyncSnapshot<AccountChainStats?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getBody(snapshot.data!);
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  List<PieChartSectionData> _getChartSections(AccountChainStats stats) =>
      List.generate(
        BlockTypeEnum.values.length,
        (int index) => _getChartSection(
          stats,
          BlockTypeEnum.values.elementAt(index),
        ),
      );

  Widget _getBlockTypeCountDetails(
    BlockTypeEnum blockType,
    int? blockTypeCount,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
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
          const SizedBox(
            width: 10,
          ),
          AutoSizeText(
            blockTypeCount.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _getChartLegend(AccountChainStats stats) {
    final List<BlockTypeEnum> typesWithBlocks = stats.blockTypeNumOfBlocksMap.keys
        .where((BlockTypeEnum key) => stats.blockTypeNumOfBlocksMap[key]! > 0)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: typesWithBlocks.length,
      itemBuilder: (BuildContext context, int index) => _getBlockTypeCountDetails(
        typesWithBlocks[index],
        stats.blockTypeNumOfBlocksMap[typesWithBlocks[index]],
      ),
    );
  }
}

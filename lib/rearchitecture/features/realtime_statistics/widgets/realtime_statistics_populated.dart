import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/realtime_statistics/widgets/realtime_txs_chart.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget associated with the [RealtimeStatisticsState] when it's status is
/// [TimerStatus.success]
///
/// Displays a chart highlighting the number of blocks in QSR and ZNN signed
/// with a particular address in the last seven days
class RealtimeStatisticsPopulated extends StatelessWidget {
  /// Creates a RealtimeStatisticsPopulated object.
  const RealtimeStatisticsPopulated({required this.accountBlocks, super.key});

  /// List of account blocks containing the ZNN and QSR transactions
  final List<AccountBlock> accountBlocks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ChartLegend(
                dotColor: ColorUtils.getTokenColor(kQsrCoin.tokenStandard),
                mainText: '${kQsrCoin.symbol} '
                    'transactions',
              ),
              const SizedBox(
                width: 10,
              ),
              ChartLegend(
                dotColor: ColorUtils.getTokenColor(kZnnCoin.tokenStandard),
                mainText: '${kZnnCoin.symbol} '
                    'transactions',
              ),
            ],
          ),
          Expanded(child: RealtimeTxsChart(accountBlocks)),
        ],
      ),
    );
  }
}

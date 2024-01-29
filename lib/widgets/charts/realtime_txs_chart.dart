import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RealtimeTxsChart extends StatefulWidget {
  final List<AccountBlock> transactions;

  const RealtimeTxsChart(
    this.transactions, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => RealtimeTxsChartState();
}

class RealtimeTxsChartState extends State<RealtimeTxsChart> {
  double _maxTransactionsPerDay = 0;

  List<FlSpot>? _znnSpots;
  List<FlSpot>? _qsrSpots;

  @override
  void initState() {
    super.initState();
    _znnSpots = _generateZnnSpots();
    _qsrSpots = _generateQsrSpots();
  }

  @override
  void didUpdateWidget(RealtimeTxsChart oldWidget) {
    // The spots variables must be generated before
    // calling super.didUpdateWidget(oldWidget).
    _znnSpots = _generateZnnSpots();
    _qsrSpots = _generateQsrSpots();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StandardChart(
      yValuesInterval: _maxTransactionsPerDay > kNumOfChartLeftSideTitles
          ? _maxTransactionsPerDay / kNumOfChartLeftSideTitles
          : 1,
      maxY: _maxTransactionsPerDay,
      lineBarsData: _linesBarData(),
      lineBarDotSymbol: 'txs',
      titlesReferenceDate: DateTime.now(),
      convertLeftSideTitlesToInt: true,
    );
  }

  double _getTransactionsByDay(TokenStandard tokenId, DateTime date) {
    var transactions = [];
    for (var transaction in widget.transactions) {
      AccountBlock? pairedAccountBlock;
      if (transaction.blockType == 3 &&
          transaction.pairedAccountBlock != null) {
        pairedAccountBlock = transaction.pairedAccountBlock!;
      }

      if (DateFormat('d MMM, yyyy').format(date) ==
          DateFormat('d MMM, yyyy').format(
            DateTime.fromMillisecondsSinceEpoch(
                (transaction.confirmationDetail?.momentumTimestamp ?? 0) *
                    1000),
          )) {
        if (transaction.tokenStandard == tokenId ||
            (pairedAccountBlock != null &&
                pairedAccountBlock.tokenStandard == tokenId)) {
          transactions.add(transaction);
        }
      }
    }

    double transactionsPerDay = transactions.length.toDouble();

    if (transactionsPerDay > _maxTransactionsPerDay) {
      _maxTransactionsPerDay = transactionsPerDay;
    }
    return transactionsPerDay;
  }

  List<LineChartBarData> _linesBarData() {
    return [
      StandardLineChartBarData(
        color: ColorUtils.getTokenColor(kZnnCoin.tokenStandard),
        spots: _znnSpots,
      ),
      StandardLineChartBarData(
        color: ColorUtils.getTokenColor(kQsrCoin.tokenStandard),
        spots: _qsrSpots,
      ),
    ];
  }

  List<FlSpot> _generateQsrSpots() {
    return List.generate(
      kStandardChartNumDays.toInt(),
      (index) => FlSpot(
        index.toDouble(),
        _getTransactionsByDay(
          kQsrCoin.tokenStandard,
          DateTime.fromMillisecondsSinceEpoch(
            FormatUtils.subtractDaysFromDate(index, DateTime.now()),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateZnnSpots() {
    return List.generate(
      kStandardChartNumDays.toInt(),
      (index) => FlSpot(
        index.toDouble(),
        _getTransactionsByDay(
          kZnnCoin.tokenStandard,
          DateTime.fromMillisecondsSinceEpoch(
            FormatUtils.subtractDaysFromDate(index, DateTime.now()),
          ),
        ),
      ),
    );
  }
}

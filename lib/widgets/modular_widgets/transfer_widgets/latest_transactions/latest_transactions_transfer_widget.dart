import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum LatestTransactionsVersion { standard, dashboard, token }

class LatestTransactions extends StatefulWidget {
  final LatestTransactionsVersion version;

  const LatestTransactions({
    Key? key,
    this.version = LatestTransactionsVersion.standard,
  }) : super(key: key);

  @override
  State<LatestTransactions> createState() => _LatestTransactionsState();
}

class _LatestTransactionsState extends State<LatestTransactions> {
  late LatestTransactionsBloc _bloc;

  List<AccountBlock>? _transactions;

  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _getWidgetTitle(),
      description: 'This card displays the latest transactions (including ZTS '
          'tokens) involving your wallet addresses',
      childBuilder: () {
        _bloc = LatestTransactionsBloc();
        return _getTable();
      },
      onRefreshPressed: () => _bloc.refreshResults(),
    );
  }

  Widget _getTable() {
    return InfiniteScrollTable<AccountBlock>(
      bloc: _bloc,
      headerColumns: widget.version == LatestTransactionsVersion.dashboard
          ? _getHeaderColumnsForDashboardWidget()
          : _getHeaderColumnsForTransferWidget(),
      generateRowCells: _rowCellsGenerator,
    );
  }

  List<Widget> _rowCellsGenerator(
    AccountBlock transaction,
    bool isSelected, {
    SentinelsListBloc? model,
  }) =>
      widget.version == LatestTransactionsVersion.dashboard
          ? _getCellsForDashboardWidget(isSelected, transaction)
          : _getCellsForTransferWidget(isSelected, transaction);

  List<Widget> _getCellsForTransferWidget(
    bool isSelected,
    AccountBlock transactionBlock,
  ) {
    AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transactionBlock.blockType)
            ? transactionBlock.pairedAccountBlock!
            : transactionBlock;
    return [
      isSelected
          ? WidgetUtils.getMarqueeAddressTableCell(infoBlock.address, context)
          : WidgetUtils.getTextAddressTableCell(infoBlock.address, context),
      isSelected
          ? WidgetUtils.getMarqueeAddressTableCell(infoBlock.toAddress, context)
          : WidgetUtils.getTextAddressTableCell(infoBlock.toAddress, context),
      isSelected
          ? InfiniteScrollTableCell.withMarquee(infoBlock.hash.toString(),
              flex: 2)
          : InfiniteScrollTableCell.withText(
              context,
              infoBlock.hash.toShortString(),
              flex: 2,
            ),
      InfiniteScrollTableCell(Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Marquee(
          animationDuration: const Duration(milliseconds: 1000),
          backDuration: const Duration(milliseconds: 1000),
          child: FormattedAmountWithTooltip(
            amount: infoBlock.amount.addDecimals(
              infoBlock.token?.decimals ?? 0,
            ),
            tokenSymbol: infoBlock.token?.symbol ?? '',
            builder: (formattedAmount, tokenSymbol) => Text(
              formattedAmount,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: AppColors.subtitleColor,
                  ),
            ),
          ),
        ),
      )),
      InfiniteScrollTableCell.withText(
        context,
        infoBlock.confirmationDetail?.momentumTimestamp == null
            ? 'Pending'
            : _formatData(
                infoBlock.confirmationDetail!.momentumTimestamp * 1000),
      ),
      InfiniteScrollTableCell(_getTransactionTypeIcon(transactionBlock)),
      InfiniteScrollTableCell(
        infoBlock.token != null ? _showTokenSymbol(infoBlock) : Container(),
      ),
    ];
  }

  List<InfiniteScrollTableHeaderColumn> _getHeaderColumnsForTransferWidget() {
    return [
      InfiniteScrollTableHeaderColumn(
        columnName: 'Sender',
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Receiver',
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Hash',
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Amount',
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Date',
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Type',
        onSortArrowsPressed: _onSortArrowsPressed,
        contentAlign: MainAxisAlignment.center,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Assets',
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
    ];
  }

  String _formatData(int transactionMillis) {
    int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(days: 1).inMilliseconds) {
      return _formatDataShort(currentMillis - transactionMillis);
    }
    return FormatUtils.formatDate(transactionMillis, dateFormat: 'MM/dd/yyyy');
  }

  String _formatDataShort(int i) {
    Duration duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ago';
    }
    return '${duration.inSeconds} s ago';
  }

  Widget _getTransactionTypeIcon(AccountBlock block) {
    if (BlockUtils.isSendBlock(block.blockType)) {
      return const Icon(
        MaterialCommunityIcons.arrow_up,
        color: AppColors.darkHintTextColor,
        size: 20.0,
      );
    }
    if (BlockUtils.isReceiveBlock(block.blockType)) {
      return const Icon(
        MaterialCommunityIcons.arrow_down,
        color: AppColors.lightHintTextColor,
        size: 20.0,
      );
    }
    return Text(
      FormatUtils.extractNameFromEnum<BlockTypeEnum>(
        BlockTypeEnum.values[block.blockType],
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }

  Widget _showTokenSymbol(AccountBlock block) {
    return Transform(
        transform: Matrix4.identity()..scale(0.8),
        alignment: Alignment.bottomCenter,
        child: Chip(
            backgroundColor: ColorUtils.getTokenColor(block.tokenStandard),
            label: Text(block.token?.symbol ?? ''),
            side: BorderSide.none,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap));
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Sender':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.address.toString().compareTo(
                      b.address.toString(),
                    ),
              )
            : _transactions!.sort(
                (a, b) => b.address.toString().compareTo(
                      a.address.toString(),
                    ),
              );
        break;
      case 'Receiver':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.toAddress.toString().compareTo(
                      b.toAddress.toString(),
                    ),
              )
            : _transactions!.sort((a, b) =>
                b.toAddress.toString().compareTo(a.toAddress.toString()));
        break;
      case 'Hash':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.hash.toString().compareTo(
                      b.hash.toString(),
                    ),
              )
            : _transactions!.sort(
                (a, b) => b.hash.toString().compareTo(
                      a.hash.toString(),
                    ),
              );
        break;
      case 'Amount':
        _sortAscending
            ? _transactions!.sort((a, b) => a.amount.compareTo(b.amount))
            : _transactions!.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Date':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.confirmationDetail!.momentumTimestamp.compareTo(
                      b.confirmationDetail!.momentumTimestamp,
                    ))
            : _transactions!.sort(
                (a, b) => b.confirmationDetail!.momentumTimestamp.compareTo(
                      a.confirmationDetail!.momentumTimestamp,
                    ));
        break;
      case 'Type':
        _sortAscending
            ? _transactions!.sort((a, b) => a.blockType.compareTo(b.blockType))
            : _transactions!.sort((a, b) => b.blockType.compareTo(a.blockType));
        break;
      case 'Assets':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.token!.symbol.compareTo(b.token!.symbol),
              )
            : _transactions!.sort(
                (a, b) => b.token!.symbol.compareTo(a.token!.symbol),
              );
        break;
      default:
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.tokenStandard.toString().compareTo(
                      b.tokenStandard.toString(),
                    ),
              )
            : _transactions!.sort(
                (a, b) => b.tokenStandard.toString().compareTo(
                      a.tokenStandard.toString(),
                    ),
              );
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  List<InfiniteScrollTableHeaderColumn> _getHeaderColumnsForDashboardWidget() {
    return [
      InfiniteScrollTableHeaderColumn(
        columnName: 'Sender',
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Amount',
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Date',
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Type',
        onSortArrowsPressed: _onSortArrowsPressed,
        contentAlign: MainAxisAlignment.center,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: 'Assets',
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
    ];
  }

  List<InfiniteScrollTableCell> _getCellsForDashboardWidget(
    bool isSelected,
    AccountBlock transactionBlock,
  ) {
    AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transactionBlock.blockType)
            ? transactionBlock.pairedAccountBlock!
            : transactionBlock;

    return [
      isSelected
          ? WidgetUtils.getMarqueeAddressTableCell(infoBlock.address, context)
          : WidgetUtils.getTextAddressTableCell(infoBlock.address, context),
      InfiniteScrollTableCell(
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Marquee(
            animationDuration: const Duration(milliseconds: 1000),
            backDuration: const Duration(milliseconds: 1000),
            child: FormattedAmountWithTooltip(
              amount: infoBlock.amount.addDecimals(
                infoBlock.token?.decimals ?? 0,
              ),
              tokenSymbol: infoBlock.token?.symbol ?? '',
              builder: (formattedAmount, tokenSymbol) => Text(
                formattedAmount,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: AppColors.subtitleColor,
                    ),
              ),
            ),
          ),
        ),
      ),
      InfiniteScrollTableCell.withText(
        context,
        infoBlock.confirmationDetail?.momentumTimestamp == null
            ? 'Pending'
            : _formatData(
                infoBlock.confirmationDetail!.momentumTimestamp * 1000,
              ),
      ),
      InfiniteScrollTableCell(_getTransactionTypeIcon(transactionBlock)),
      InfiniteScrollTableCell(
        infoBlock.token != null ? _showTokenSymbol(infoBlock) : Container(),
      )
    ];
  }

  String _getWidgetTitle() => widget.version == LatestTransactionsVersion.token
      ? 'Token Transactions'
      : 'Latest Transactions';
}

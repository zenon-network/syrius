import 'package:flutter/material.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/pending_transactions_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PendingTransactions extends StatefulWidget {
  const PendingTransactions({
    Key? key,
  }) : super(key: key);

  @override
  State<PendingTransactions> createState() => _PendingTransactionsState();
}

class _PendingTransactionsState extends State<PendingTransactions> {
  late PendingTransactionsBloc _bloc;
  List<AccountBlock>? _transactions;

  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _bloc = PendingTransactionsBloc();
    _bloc.refreshResults();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _getWidgetTitle(),
      description: 'This card displays the pending transactions (including ZTS '
          'tokens) involving your wallet addresses',
      childBuilder: () {
        _bloc = PendingTransactionsBloc();
        return _getTable();
      },
      onRefreshPressed: () => _bloc.refreshResults(),
    );
  }

  Widget _getTable() {
    return InfiniteScrollTable<AccountBlock>(
      bloc: _bloc,
      generateRowCells: _rowCellsGenerator,
      headerColumns: _getHeaderColumnsForTransferWidget(),
    );
  }

  List<Widget> _rowCellsGenerator(AccountBlock transaction, bool isSelected) =>
      _getCellsForPendingTransferWidget(isSelected, transaction);

  List<Widget> _getCellsForPendingTransferWidget(
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
            : FormatUtils.formatData(
                infoBlock.confirmationDetail!.momentumTimestamp * 1000),
      ),
      InfiniteScrollTableCell(
        Align(
            alignment: Alignment.centerLeft,
            child: infoBlock.token != null
                ? _showTokenSymbol(infoBlock)
                : Container()),
      ),
      InfiniteScrollTableCell(Align(
          alignment: Alignment.centerLeft,
          child: _getReceiveButton(transactionBlock.hash))),
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
        columnName: 'Assets',
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      const InfiniteScrollTableHeaderColumn(
        columnName: '',
      ),
    ];
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

  Widget _getReceiveButton(Hash txHash) {
    return MaterialIconButton(
      size: 25.0,
      iconData: Icons.download_for_offline,
      onPressed: () {
        sl<AutoReceiveTxWorker>().autoReceiveTransactionHash(txHash);
        setState(() {});
      },
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

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  String _getWidgetTitle() => 'Pending Transactions';
}
import 'package:flutter/material.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/pending_transactions_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/receive_transaction_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PendingTransactions extends StatefulWidget {
  const PendingTransactions({
    super.key,
  });

  @override
  State<PendingTransactions> createState() => _PendingTransactionsState();
}

class _PendingTransactionsState extends State<PendingTransactions> {
  late PendingTransactionsBloc _bloc;
  List<AccountBlock>? _transactions;

  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _getWidgetTitle(),
      description: 'This card displays the pending transactions (including ZTS '
          'tokens) for the selected address',
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
      headerColumns: _getHeaderColumnsForPendingTransactions(),
    );
  }

  List<Widget> _rowCellsGenerator(AccountBlock transaction, bool isSelected) =>
      _getCellsForPendingTransactions(isSelected, transaction);

  List<Widget> _getCellsForPendingTransactions(
      bool isSelected, AccountBlock transaction,) {
    final infoBlock = BlockUtils.isReceiveBlock(transaction.blockType)
        ? transaction.pairedAccountBlock!
        : transaction;
    return [
      if (isSelected) WidgetUtils.getMarqueeAddressTableCell(infoBlock.address, context) else WidgetUtils.getTextAddressTableCell(infoBlock.address, context),
      if (isSelected) WidgetUtils.getMarqueeAddressTableCell(infoBlock.toAddress, context) else WidgetUtils.getTextAddressTableCell(infoBlock.toAddress, context),
      if (isSelected) InfiniteScrollTableCell.withMarquee(infoBlock.hash.toString(),
              flex: 2,) else InfiniteScrollTableCell.withText(
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
      ),),
      InfiniteScrollTableCell.withText(
        context,
        infoBlock.confirmationDetail?.momentumTimestamp == null
            ? 'Pending'
            : FormatUtils.formatData(
                infoBlock.confirmationDetail!.momentumTimestamp * 1000,),
      ),
      InfiniteScrollTableCell(
        Align(
            alignment: Alignment.centerLeft,
            child: infoBlock.token != null
                ? _showTokenSymbol(infoBlock)
                : Container(),),
      ),
      InfiniteScrollTableCell(
          _getReceiveContainer(isSelected, infoBlock, _bloc),),
    ];
  }

  List<InfiniteScrollTableHeaderColumn>
      _getHeaderColumnsForPendingTransactions() {
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
      case 'Receiver':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.toAddress.toString().compareTo(
                      b.toAddress.toString(),
                    ),
              )
            : _transactions!.sort((a, b) =>
                b.toAddress.toString().compareTo(a.toAddress.toString()),);
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
      case 'Amount':
        _sortAscending
            ? _transactions!.sort((a, b) => a.amount.compareTo(b.amount))
            : _transactions!.sort((a, b) => b.amount.compareTo(a.amount));
      case 'Date':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.confirmationDetail!.momentumTimestamp.compareTo(
                      b.confirmationDetail!.momentumTimestamp,
                    ),)
            : _transactions!.sort(
                (a, b) => b.confirmationDetail!.momentumTimestamp.compareTo(
                      a.confirmationDetail!.momentumTimestamp,
                    ),);
      case 'Assets':
        _sortAscending
            ? _transactions!.sort(
                (a, b) => a.token!.symbol.compareTo(b.token!.symbol),
              )
            : _transactions!.sort(
                (a, b) => b.token!.symbol.compareTo(a.token!.symbol),
              );
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

  Widget _getReceiveContainer(
    bool isSelected,
    AccountBlock transaction,
    PendingTransactionsBloc model,
  ) {
    return Align(
        alignment: Alignment.centerLeft,
        child: _getReceiveButtonViewModel(model, isSelected, transaction),);
  }

  Widget _getReceiveButtonViewModel(
    PendingTransactionsBloc transactionModel,
    bool isSelected,
    AccountBlock transactionItem,
  ) {
    return ViewModelBuilder<ReceiveTransactionBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              transactionModel.refreshResults();
            }
          },
          onError: (error) async {
            await NotificationUtils.sendNotificationError(
                error, 'Error while receiving transaction',);
          },
        );
      },
      builder: (_, model, __) => _getReceiveButton(
        model,
        transactionItem.hash.toString(),
      ),
      viewModelBuilder: ReceiveTransactionBloc.new,
    );
  }

  Widget _getReceiveButton(
    ReceiveTransactionBloc model,
    String transactionHash,
  ) {
    return MaterialIconButton(
      size: 25,
      iconData: Icons.download_for_offline,
      onPressed: () {
        _onReceivePressed(model, transactionHash);
      },
    );
  }

  void _onReceivePressed(ReceiveTransactionBloc model, String id) {
    model.receiveTransaction(id, context);
  }

  Widget _showTokenSymbol(AccountBlock block) {
    return Transform(
        transform: Matrix4.identity()..scale(0.8),
        alignment: Alignment.bottomCenter,
        child: Chip(
            backgroundColor: ColorUtils.getTokenColor(block.tokenStandard),
            label: Text(block.token?.symbol ?? ''),
            side: BorderSide.none,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,),);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  String _getWidgetTitle() => 'Pending Transactions';
}

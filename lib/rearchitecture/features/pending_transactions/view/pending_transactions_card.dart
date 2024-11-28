import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pending_transactions/pending_transactions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PendingTransactionsCard extends StatelessWidget {
  const PendingTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final PendingTransactionsBloc bloc =
        context.read<PendingTransactionsBloc>();

    return NewCardScaffold(
      data: CardType.pendingTransactions.getData(context: context),
      onRefreshPressed: () {
        bloc.add(
          InfiniteListRefreshRequested(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
      body:
          BlocBuilder<PendingTransactionsBloc, InfiniteListState<AccountBlock>>(
        builder: (_, InfiniteListState<AccountBlock> state) {
          final InfiniteListStatus status = state.status;

          return switch (status) {
            InfiniteListStatus.initial => const _PendingTransactionsInitial(),
            InfiniteListStatus.failure => _PendingTransactionsFailure(
                exception: state.error!,
              ),
            InfiniteListStatus.success => _PendingTransactionsPopulated(
                bloc: bloc,
                hasReachedMax: state.hasReachedMax,
                transactions: state.data!,
              ),
          };
        },
      ),
    );
  }
}

class _PendingTransactionsInitial extends StatelessWidget {
  const _PendingTransactionsInitial();

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}

class _PendingTransactionsFailure extends StatelessWidget {
  const _PendingTransactionsFailure({required this.exception});

  final SyriusException exception;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(exception.message);
  }
}

class _PendingTransactionsPopulated extends StatefulWidget {
  const _PendingTransactionsPopulated({
    required this.bloc,
    required this.hasReachedMax,
    required this.transactions,
  });

  final PendingTransactionsBloc bloc;
  final bool hasReachedMax;
  final List<AccountBlock> transactions;

  @override
  State<_PendingTransactionsPopulated> createState() =>
      _PendingTransactionsPopulatedState();
}

class _PendingTransactionsPopulatedState
    extends State<_PendingTransactionsPopulated> {
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<AccountBlock>(
      generateRowCells: _rowCellsGenerator,
      hasReachedMax: widget.hasReachedMax,
      columns: _getHeaderColumnsForPendingTransactions(),
      items: widget.transactions,
      onScrollReachedBottom: () {
        widget.bloc.add(
          InfiniteListRequested(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
    );
  }

  List<Widget> _rowCellsGenerator(AccountBlock transaction) =>
      _getCellsForPendingTransactions(transaction);

  List<Widget> _getCellsForPendingTransactions(
    AccountBlock transaction,
  ) {
    final AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transaction.blockType)
            ? transaction.pairedAccountBlock!
            : transaction;
    return <Widget>[
      InfiniteScrollTableCell.textFromAddress(
        address: infoBlock.address,
        context: context,
      ),
      InfiniteScrollTableCell.textFromAddress(
        address: infoBlock.toAddress,
        context: context,
      ),
      InfiniteScrollTableCell.withText(
        content: infoBlock.hash.toShortString(),
        context: context,
        flex: 2,
        textToBeCopied: infoBlock.hash.toString(),
        tooltipMessage: infoBlock.hash.toString(),
      ),
      InfiniteScrollTableCell(
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: FormattedAmountWithTooltip(
            amount: infoBlock.amount.addDecimals(
              infoBlock.token?.decimals ?? 0,
            ),
            tokenSymbol: infoBlock.token?.symbol ?? '',
            builder: (String formattedAmount, String tokenSymbol) => Text(
              formattedAmount,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: AppColors.subtitleColor,
                  ),
            ),
          ),
        ),
      ),
      InfiniteScrollTableCell.withText(
        content: infoBlock.confirmationDetail?.momentumTimestamp == null
            ? context.l10n.pending
            : FormatUtils.formatData(
                infoBlock.confirmationDetail!.momentumTimestamp * 1000,
              ),
        context: context,
      ),
      _assetsCell(infoBlock),
      InfiniteScrollTableCell(
        child: _getReceiveButton(hash: infoBlock.hash),
      ),
    ];
  }

  List<InfiniteScrollTableColumnType>
      _getHeaderColumnsForPendingTransactions() {
    return <InfiniteScrollTableColumnType>[
      InfiniteScrollTableColumnType.sender,
      InfiniteScrollTableColumnType.receiver,
      InfiniteScrollTableColumnType.hash,
      InfiniteScrollTableColumnType.amount,
      InfiniteScrollTableColumnType.date,
      InfiniteScrollTableColumnType.asset,
      InfiniteScrollTableColumnType.blank,
    ];
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Sender':
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.address.toString().compareTo(
                          b.address.toString(),
                        ),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.address.toString().compareTo(
                          a.address.toString(),
                        ),
              );
      case 'Receiver':
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.toAddress.toString().compareTo(
                          b.toAddress.toString(),
                        ),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.toAddress.toString().compareTo(
                          a.toAddress.toString(),
                        ),
              );
      case 'Hash':
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) => a.hash.toString().compareTo(
                      b.hash.toString(),
                    ),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) => b.hash.toString().compareTo(
                      a.hash.toString(),
                    ),
              );
      case 'Amount':
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.amount.compareTo(b.amount),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.amount.compareTo(a.amount),
              );
      case 'Date':
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.confirmationDetail!.momentumTimestamp.compareTo(
                  b.confirmationDetail!.momentumTimestamp,
                ),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.confirmationDetail!.momentumTimestamp.compareTo(
                  a.confirmationDetail!.momentumTimestamp,
                ),
              );
      case 'Assets':
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.token!.symbol.compareTo(b.token!.symbol),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.token!.symbol.compareTo(a.token!.symbol),
              );
      default:
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.tokenStandard.toString().compareTo(
                          b.tokenStandard.toString(),
                        ),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.tokenStandard.toString().compareTo(
                          a.tokenStandard.toString(),
                        ),
              );
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  Widget _getReceiveButton({
    required Hash hash,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: context.l10n.pressToReceive,
        icon: const Icon(Icons.call_received_rounded),
        color: AppColors.znnColor,
        onPressed: () {
          sl<AutoReceiveTxWorker>().autoReceiveTransactionHash(
            hash,
          );
        },
      ),
    );
  }

  InfiniteScrollTableCell _assetsCell(AccountBlock infoBlock) {
    late final Widget child;
    if (infoBlock.token == null) {
      child = const SizedBox.shrink();
    } else {
      child = Chip(
        backgroundColor: ColorUtils.getTokenColor(infoBlock.tokenStandard),
        label: Text(infoBlock.token?.symbol ?? ''),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    return InfiniteScrollTableCell(
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

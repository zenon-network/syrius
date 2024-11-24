import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pending_transactions/pending_transactions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
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
          PendingTransactionsRefreshRequested(
            Address.parse(kSelectedAddress!),
          ),
        );
      },
      body: BlocBuilder<PendingTransactionsBloc, PendingTransactionsState>(
        builder: (_, PendingTransactionsState state) {
          final PendingTransactionsStatus status = state.status;

          return switch (status) {
            PendingTransactionsStatus.initial =>
              const _PendingTransactionsInitial(),
            PendingTransactionsStatus.failure => _PendingTransactionsFailure(
                exception: state.error!,
              ),
            PendingTransactionsStatus.success => _PendingTransactionsPopulated(
                bloc: bloc,
                hasReachedMax: state.hasReachedMax,
                transactions: state.data,
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
    return NewInfiniteScrollTable<AccountBlock>(
      generateRowCells: _rowCellsGenerator,
      hasReachedMax: widget.hasReachedMax,
      headerColumns: _getHeaderColumnsForPendingTransactions(),
      items: widget.transactions,
      onScrollReachedBottom: () {
        widget.bloc.add(
          PendingTransactionsRequested(
            Address.parse(kSelectedAddress!),
          ),
        );
      },
    );
  }

  List<Widget> _rowCellsGenerator(AccountBlock transaction, bool isSelected) =>
      _getCellsForPendingTransactions(isSelected, transaction);

  List<Widget> _getCellsForPendingTransactions(
    bool isSelected,
    AccountBlock transaction,
  ) {
    final AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transaction.blockType)
            ? transaction.pairedAccountBlock!
            : transaction;
    return <Widget>[
      NewInfiniteScrollTableCell.textFromAddress(
        infoBlock.address,
        context,
      ),
      NewInfiniteScrollTableCell.textFromAddress(
        infoBlock.toAddress,
        context,
      ),
      NewInfiniteScrollTableCell.withText(
        context,
        infoBlock.hash.toShortString(),
        flex: 2,
        tooltipMessage: infoBlock.hash.toString(),
        textToBeCopied: infoBlock.hash.toString(),
      ),
      NewInfiniteScrollTableCell(
        Padding(
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
      NewInfiniteScrollTableCell.withText(
        context,
        infoBlock.confirmationDetail?.momentumTimestamp == null
            ? context.l10n.pending
            : FormatUtils.formatData(
                infoBlock.confirmationDetail!.momentumTimestamp * 1000,
              ),
      ),
      _assetsCell(infoBlock),
      NewInfiniteScrollTableCell(
        _getReceiveContainer(isSelected, infoBlock, widget.bloc),
      ),
    ];
  }

  List<NewInfiniteScrollTableHeaderColumn>
      _getHeaderColumnsForPendingTransactions() {
    return <NewInfiniteScrollTableHeaderColumn>[
      NewInfiniteScrollTableHeaderColumn(
        columnName: context.l10n.sender,
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      NewInfiniteScrollTableHeaderColumn(
        columnName: context.l10n.receiver,
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      NewInfiniteScrollTableHeaderColumn(
        columnName: context.l10n.hash,
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      NewInfiniteScrollTableHeaderColumn(
        columnName: context.l10n.amount,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      NewInfiniteScrollTableHeaderColumn(
        columnName: context.l10n.date,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      NewInfiniteScrollTableHeaderColumn(
        columnName: context.l10n.assets,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      const NewInfiniteScrollTableHeaderColumn(
        columnName: '',
      ),
    ];
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Sender':
        _sortAscending
            ? widget.transactions.sort(
                (a, b) => a.address.toString().compareTo(
                      b.address.toString(),
                    ),
              )
            : widget.transactions.sort(
                (a, b) => b.address.toString().compareTo(
                      a.address.toString(),
                    ),
              );
        break;
      case 'Receiver':
        _sortAscending
            ? widget.transactions.sort(
                (a, b) => a.toAddress.toString().compareTo(
                      b.toAddress.toString(),
                    ),
              )
            : widget.transactions.sort(
                (a, b) => b.toAddress.toString().compareTo(
                      a.toAddress.toString(),
                    ),
              );
        break;
      case 'Hash':
        _sortAscending
            ? widget.transactions.sort(
                (a, b) => a.hash.toString().compareTo(
                      b.hash.toString(),
                    ),
              )
            : widget.transactions.sort(
                (a, b) => b.hash.toString().compareTo(
                      a.hash.toString(),
                    ),
              );
        break;
      case 'Amount':
        _sortAscending
            ? widget.transactions.sort((a, b) => a.amount.compareTo(b.amount))
            : widget.transactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Date':
        _sortAscending
            ? widget.transactions.sort(
                (a, b) => a.confirmationDetail!.momentumTimestamp.compareTo(
                  b.confirmationDetail!.momentumTimestamp,
                ),
              )
            : widget.transactions.sort(
                (a, b) => b.confirmationDetail!.momentumTimestamp.compareTo(
                  a.confirmationDetail!.momentumTimestamp,
                ),
              );
        break;
      case 'Assets':
        _sortAscending
            ? widget.transactions.sort(
                (a, b) => a.token!.symbol.compareTo(b.token!.symbol),
              )
            : widget.transactions.sort(
                (a, b) => b.token!.symbol.compareTo(a.token!.symbol),
              );
        break;
      default:
        _sortAscending
            ? widget.transactions.sort(
                (a, b) => a.tokenStandard.toString().compareTo(
                      b.tokenStandard.toString(),
                    ),
              )
            : widget.transactions.sort(
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
      child: _getReceiveButton(hash: transaction.hash),
    );
  }

  Widget _getReceiveButton({
    required Hash hash,
}
  ) {
    return IconButton(
      icon: const Icon(MaterialCommunityIcons.arrow_down),
      color: AppColors.znnColor,
      onPressed: () {
        sl<AutoReceiveTxWorker>().autoReceiveTransactionHash(
          hash,
        );
      },
    );
  }

  NewInfiniteScrollTableCell _assetsCell(AccountBlock infoBlock) {
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

    return NewInfiniteScrollTableCell(
      Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

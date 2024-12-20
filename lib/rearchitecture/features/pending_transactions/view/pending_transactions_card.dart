import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the current pending transactions.
///
/// Optionally, the user can request for a specific transaction to be received.
class PendingTransactionsCard extends StatelessWidget {
  /// Creates a new instance.
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
      AddressCell(
        address: infoBlock.address,
      ),
      AddressCell(
        address: infoBlock.toAddress,
      ),
      HashCell(
        hash: infoBlock.hash,
      ),
      AmountCell(block: infoBlock),
      DateCell(
        block: infoBlock,
      ),
      AssetCell(block: infoBlock),
      ReceiveCell(hash: infoBlock.hash),
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

  // TODO(maznnwell): to be used when sorting is enabled
  // ignore: unused_element
  void _onSortArrowsPressed(InfiniteScrollTableColumnType columnType) {
    switch (columnType) {
      case InfiniteScrollTableColumnType.sender:
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
      case InfiniteScrollTableColumnType.receiver:
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
      case InfiniteScrollTableColumnType.hash:
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
      case InfiniteScrollTableColumnType.amount:
        _sortAscending
            ? widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.amount.compareTo(b.amount),
              )
            : widget.transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.amount.compareTo(a.amount),
              );
      case InfiniteScrollTableColumnType.date:
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
      case InfiniteScrollTableColumnType.asset:
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
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }
}

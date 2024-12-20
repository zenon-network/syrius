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

/// A widget that displayed the latest transactions for an address
class LatestTransactionsCard extends StatelessWidget {
  /// Creates a new instance.
  ///
  /// There is also a check to make sure that the [type] can be found among
  /// the supported list of types
  LatestTransactionsCard({required this.type, super.key})
      : assert(
          <CardType>[
            CardType.latestTransactions,
            CardType.latestTransactionsDashboard,
          ].contains(type),
          'make sure that the type refers only to latest transactions types',
        );

  /// The card type, either [CardType.latestTransactions] or
  /// [CardType.latestTransactionsDashboard]
  final CardType type;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardType.latestTransactions.getData(context: context),
      onRefreshPressed: () {
        context.read<LatestTransactionsBloc>().add(
              InfiniteListRefreshRequested(
                address: Address.parse(kSelectedAddress!),
              ),
            );
      },
      body:
          BlocBuilder<LatestTransactionsBloc, InfiniteListState<AccountBlock>>(
        builder: (_, InfiniteListState<AccountBlock> state) {
          final InfiniteListStatus status = state.status;

          return switch (status) {
            InfiniteListStatus.initial => const _LatestTransactionsInitial(),
            InfiniteListStatus.failure => _LatestTransactionsFailure(
                exception: state.error!,
              ),
            InfiniteListStatus.success => _LatestTransactionsPopulated(
                hasReachedMax: state.hasReachedMax,
                transactions: state.data!,
                type: type,
              ),
          };
        },
      ),
    );
  }
}

class _LatestTransactionsInitial extends StatelessWidget {
  const _LatestTransactionsInitial();

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}

class _LatestTransactionsFailure extends StatelessWidget {
  const _LatestTransactionsFailure({required this.exception});

  final SyriusException exception;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(exception);
  }
}

class _LatestTransactionsPopulated extends StatefulWidget {
  const _LatestTransactionsPopulated({
    required this.hasReachedMax,
    required this.transactions,
    required this.type,
  });

  final bool hasReachedMax;
  final List<AccountBlock> transactions;
  final CardType type;

  @override
  State<_LatestTransactionsPopulated> createState() =>
      _LatestTransactionsPopulatedState();
}

class _LatestTransactionsPopulatedState
    extends State<_LatestTransactionsPopulated> {
  late List<AccountBlock> _transactions;

  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<AccountBlock>(
      items: widget.transactions,
      hasReachedMax: widget.hasReachedMax,
      columns: widget.type == CardType.latestTransactionsDashboard
          ? _getHeaderColumnsForDashboardWidget()
          : _getHeaderColumnsForTransferWidget(),
      generateRowCells: _rowCellsGenerator,
      onScrollReachedBottom: () {
        context.read<LatestTransactionsBloc>().add(
              InfiniteListMoreRequested(
                address: Address.parse(kSelectedAddress!),
              ),
            );
      },
    );
  }

  List<Widget> _rowCellsGenerator(
    AccountBlock transaction,
  ) =>
      widget.type == CardType.latestTransactionsDashboard
          ? _getCellsForDashboardWidget(transaction)
          : _getCellsForTransferWidget(transaction);

  List<Widget> _getCellsForTransferWidget(
    AccountBlock transactionBlock,
  ) {
    final AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transactionBlock.blockType)
            ? transactionBlock.pairedAccountBlock!
            : transactionBlock;
    return <Widget>[
      AddressCell(
        address: infoBlock.address,
      ),
      AddressCell(
        address: infoBlock.toAddress,
      ),
      HashCell(hash: infoBlock.hash),
      AmountCell(block: infoBlock),
      DateCell(block: infoBlock),
      TypeCell(block: transactionBlock),
      AssetCell(block: infoBlock),
    ];
  }

  List<InfiniteScrollTableColumnType> _getHeaderColumnsForTransferWidget() {
    return <InfiniteScrollTableColumnType>[
      InfiniteScrollTableColumnType.sender,
      InfiniteScrollTableColumnType.receiver,
      InfiniteScrollTableColumnType.hash,
      InfiniteScrollTableColumnType.amount,
      InfiniteScrollTableColumnType.date,
      InfiniteScrollTableColumnType.type,
      InfiniteScrollTableColumnType.asset,
    ];
  }

  List<InfiniteScrollTableColumnType> _getHeaderColumnsForDashboardWidget() {
    return <InfiniteScrollTableColumnType>[
      InfiniteScrollTableColumnType.sender,
      InfiniteScrollTableColumnType.amount,
      InfiniteScrollTableColumnType.date,
      InfiniteScrollTableColumnType.type,
      InfiniteScrollTableColumnType.asset,
    ];
  }

  List<Widget> _getCellsForDashboardWidget(
    AccountBlock transactionBlock,
  ) {
    final AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transactionBlock.blockType)
            ? transactionBlock.pairedAccountBlock!
            : transactionBlock;

    return <Widget>[
      AddressCell(address: infoBlock.address),
      AmountCell(block: infoBlock),
      DateCell(block: infoBlock),
      TypeCell(block: transactionBlock),
      AssetCell(block: infoBlock),
    ];
  }

  // TODO(maznnwell): to be used when sorting is enabled
  // ignore: unused_element
  void _onSortArrowsPressed(InfiniteScrollTableColumnType columnType) {
    switch (columnType) {
      case InfiniteScrollTableColumnType.sender:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.address.toString().compareTo(
                          b.address.toString(),
                        ),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.address.toString().compareTo(
                          a.address.toString(),
                        ),
              );
      case InfiniteScrollTableColumnType.receiver:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.toAddress.toString().compareTo(
                          b.toAddress.toString(),
                        ),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.toAddress.toString().compareTo(
                          a.toAddress.toString(),
                        ),
              );
      case InfiniteScrollTableColumnType.hash:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) => a.hash.toString().compareTo(
                      b.hash.toString(),
                    ),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) => b.hash.toString().compareTo(
                      a.hash.toString(),
                    ),
              );
      case InfiniteScrollTableColumnType.amount:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.amount.compareTo(b.amount),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.amount.compareTo(a.amount),
              );
      case InfiniteScrollTableColumnType.date:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.confirmationDetail!.momentumTimestamp.compareTo(
                  b.confirmationDetail!.momentumTimestamp,
                ),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.confirmationDetail!.momentumTimestamp.compareTo(
                  a.confirmationDetail!.momentumTimestamp,
                ),
              );
      case InfiniteScrollTableColumnType.type:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.blockType.compareTo(b.blockType),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.blockType.compareTo(a.blockType),
              );
      case InfiniteScrollTableColumnType.asset:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.token!.symbol.compareTo(b.token!.symbol),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.token!.symbol.compareTo(a.token!.symbol),
              );
      default:
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.tokenStandard.toString().compareTo(
                          b.tokenStandard.toString(),
                        ),
              )
            : _transactions.sort(
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
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
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

class LatestTransactionsCard extends StatelessWidget {
  LatestTransactionsCard({required this.type, super.key})
      : assert(
          <CardType>[
            CardType.latestTransactions,
            CardType.latestTransactionsDashboard,
          ].contains(type),
          'make sure that the type refers only to latest transactions types',
        );

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
      headerColumns: widget.type == CardType.latestTransactionsDashboard
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
        tooltipMessage: infoBlock.hash.toString(),
        textToBeCopied: infoBlock.hash.toString(),
      ),
      _amountCell(infoBlock),
      _dateCell(infoBlock),
      _typeCell(transactionBlock),
      _assetsCell(infoBlock),
    ];
  }

  InfiniteScrollTableCell _dateCell(AccountBlock infoBlock) {
    return InfiniteScrollTableCell.withText(
      content: infoBlock.confirmationDetail?.momentumTimestamp == null
          ? context.l10n.pending
          : FormatUtils.formatData(
              infoBlock.confirmationDetail!.momentumTimestamp * 1000,
            ),
      context: context,
    );
  }

  List<InfiniteScrollTableHeaderColumn> _getHeaderColumnsForTransferWidget() {
    return <InfiniteScrollTableHeaderColumn>[
      _senderColumn(),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.receiver,
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.hash,
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      _amountColumn(),
      _dateColumn(),
      _typeColumn(),
      _assetsColumn(),
    ];
  }

  InfiniteScrollTableHeaderColumn _amountColumn() {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.amount,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  InfiniteScrollTableHeaderColumn _senderColumn() {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.sender,
      onSortArrowsPressed: _onSortArrowsPressed,
      flex: 2,
    );
  }

  List<InfiniteScrollTableHeaderColumn> _getHeaderColumnsForDashboardWidget() {
    return <InfiniteScrollTableHeaderColumn>[
      _senderColumn(),
      _amountColumn(),
      _dateColumn(),
      _typeColumn(),
      _assetsColumn(),
    ];
  }

  InfiniteScrollTableHeaderColumn _assetsColumn() {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.assets,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  InfiniteScrollTableHeaderColumn _typeColumn() {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.type,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  InfiniteScrollTableHeaderColumn _dateColumn() {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.date,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  List<Widget> _getCellsForDashboardWidget(
    AccountBlock transactionBlock,
  ) {
    final AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transactionBlock.blockType)
            ? transactionBlock.pairedAccountBlock!
            : transactionBlock;

    return <Widget>[
      _senderCell(address: infoBlock.address),
      _amountCell(infoBlock),
      _dateCell(infoBlock),
      _typeCell(transactionBlock),
      _assetsCell(infoBlock),
    ];
  }

  InfiniteScrollTableCell _typeCell(
    AccountBlock transactionBlock,
  ) {
    return InfiniteScrollTableCell(
      child: Align(
        alignment: Alignment.centerLeft,
        child: _getTransactionTypeIcon(transactionBlock),
      ),
    );
  }

  InfiniteScrollTableCell _amountCell(AccountBlock infoBlock) {
    return InfiniteScrollTableCell(
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
    );
  }

  InfiniteScrollTableCell _senderCell({required Address address}) =>
      InfiniteScrollTableCell.textFromAddress(
        address: address,
        context: context,
      );

  Widget _getTransactionTypeIcon(AccountBlock block) {
    if (BlockUtils.isSendBlock(block.blockType)) {
      return Tooltip(
        message: context.l10n.send,
        child: const Icon(
          Icons.call_made_rounded,
          color: AppColors.errorColor,
        ),
      );
    }
    if (BlockUtils.isReceiveBlock(block.blockType)) {
      return Tooltip(
        message: context.l10n.receive,
        child: const Icon(
          Icons.call_received_rounded,
          color: AppColors.znnColor,
        ),
      );
    }
    return Text(
      FormatUtils.extractNameFromEnum<BlockTypeEnum>(
        BlockTypeEnum.values[block.blockType],
      ),
      textAlign: TextAlign.start,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }

  InfiniteScrollTableCell _assetsCell(AccountBlock infoBlock) {
    late final Widget child;
    if (infoBlock.token == null) {
      child = const SizedBox.shrink();
    } else {
      child = Tooltip(
        message: infoBlock.token!.tokenStandard.toString(),
        child: Text(
          infoBlock.token?.symbol ?? '',
          style: TextStyle(
            color: ColorUtils.getTokenColor(infoBlock.tokenStandard),
          ),
        ),
      );
    }

    return InfiniteScrollTableCell(
      child: child,
    );
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Sender':
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
      case 'Receiver':
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
      case 'Hash':
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
      case 'Amount':
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.amount.compareTo(b.amount),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.amount.compareTo(a.amount),
              );
      case 'Date':
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
      case 'Type':
        _sortAscending
            ? _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    a.blockType.compareTo(b.blockType),
              )
            : _transactions.sort(
                (AccountBlock a, AccountBlock b) =>
                    b.blockType.compareTo(a.blockType),
              );
      case 'Assets':
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

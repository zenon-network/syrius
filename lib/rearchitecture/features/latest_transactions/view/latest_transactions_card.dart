import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
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
              LatestTransactionsRefreshRequested(
                address: Address.parse(kSelectedAddress!),
              ),
            );
      },
      body: BlocBuilder<LatestTransactionsBloc, LatestTransactionsState>(
        builder: (_, LatestTransactionsState state) {
          final LatestTransactionsStatus status = state.status;

          return switch (status) {
            LatestTransactionsStatus.initial =>
              const _LatestTransactionsInitial(),
            LatestTransactionsStatus.failure => _LatestTransactionsFailure(
                exception: state.error!,
              ),
            LatestTransactionsStatus.success => _LatestTransactionsPopulated(
                hasReachedMax: state.hasReachedMax,
                transactions: state.data,
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
    return NewInfiniteScrollTable<AccountBlock>(
      items: widget.transactions,
      hasReachedMax: widget.hasReachedMax,
      headerColumns: widget.type == CardType.latestTransactionsDashboard
          ? _getHeaderColumnsForDashboardWidget()
          : _getHeaderColumnsForTransferWidget(),
      generateRowCells: _rowCellsGenerator,
      onScrollReachedBottom: () {
        context.read<LatestTransactionsBloc>().add(
              LatestTransactionsMoreRequested(
                address: Address.parse(kSelectedAddress!),
              ),
            );
      },
    );
  }

  List<Widget> _rowCellsGenerator(
    AccountBlock transaction,
    bool isSelected,
  ) =>
      widget.type == CardType.latestTransactionsDashboard
          ? _getCellsForDashboardWidget(isSelected, transaction)
          : _getCellsForTransferWidget(isSelected, transaction);

  List<Widget> _getCellsForTransferWidget(
    bool isSelected,
    AccountBlock transactionBlock,
  ) {
    final AccountBlock infoBlock =
        BlockUtils.isReceiveBlock(transactionBlock.blockType)
            ? transactionBlock.pairedAccountBlock!
            : transactionBlock;
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
      _amountCell(infoBlock),
      _dateCell(infoBlock),
      _typeCell(transactionBlock),
      _assetsCell(infoBlock),
    ];
  }

  NewInfiniteScrollTableCell _dateCell(AccountBlock infoBlock) {
    return NewInfiniteScrollTableCell.withText(
      context,
      infoBlock.confirmationDetail?.momentumTimestamp == null
          ? context.l10n.pending
          : FormatUtils.formatData(
              infoBlock.confirmationDetail!.momentumTimestamp * 1000,
            ),
    );
  }

  List<NewInfiniteScrollTableHeaderColumn>
      _getHeaderColumnsForTransferWidget() {
    return <NewInfiniteScrollTableHeaderColumn>[
      _senderColumn(),
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
      _amountColumn(),
      _dateColumn(),
      _typeColumn(),
      _assetsColumn(),
    ];
  }

  NewInfiniteScrollTableHeaderColumn _amountColumn() {
    return NewInfiniteScrollTableHeaderColumn(
      columnName: context.l10n.amount,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  NewInfiniteScrollTableHeaderColumn _senderColumn() {
    return NewInfiniteScrollTableHeaderColumn(
      columnName: context.l10n.sender,
      onSortArrowsPressed: _onSortArrowsPressed,
      flex: 2,
    );
  }

  List<NewInfiniteScrollTableHeaderColumn>
      _getHeaderColumnsForDashboardWidget() {
    return <NewInfiniteScrollTableHeaderColumn>[
      _senderColumn(),
      _amountColumn(),
      _dateColumn(),
      _typeColumn(),
      _assetsColumn(),
    ];
  }

  NewInfiniteScrollTableHeaderColumn _assetsColumn() {
    return NewInfiniteScrollTableHeaderColumn(
      columnName: context.l10n.assets,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  NewInfiniteScrollTableHeaderColumn _typeColumn() {
    return NewInfiniteScrollTableHeaderColumn(
      columnName: context.l10n.type,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  NewInfiniteScrollTableHeaderColumn _dateColumn() {
    return NewInfiniteScrollTableHeaderColumn(
      columnName: context.l10n.date,
      onSortArrowsPressed: _onSortArrowsPressed,
    );
  }

  List<Widget> _getCellsForDashboardWidget(
    bool isSelected,
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

  NewInfiniteScrollTableCell _typeCell(
    AccountBlock transactionBlock,
  ) {
    return NewInfiniteScrollTableCell(
      Align(
        alignment: Alignment.centerLeft,
        child: _getTransactionTypeIcon(transactionBlock),
      ),
    );
  }

  NewInfiniteScrollTableCell _amountCell(AccountBlock infoBlock) {
    return NewInfiniteScrollTableCell(
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
    );
  }

  NewInfiniteScrollTableCell _senderCell({required Address address}) =>
      NewInfiniteScrollTableCell.textFromAddress(
        address,
        context,
      );

  Widget _getTransactionTypeIcon(AccountBlock block) {
    if (BlockUtils.isSendBlock(block.blockType)) {
      return const Icon(
        MaterialCommunityIcons.arrow_up,
        color: AppColors.darkHintTextColor,
        size: 20,
      );
    }
    if (BlockUtils.isReceiveBlock(block.blockType)) {
      return const Icon(
        MaterialCommunityIcons.arrow_down,
        color: AppColors.lightHintTextColor,
        size: 20,
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

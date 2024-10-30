import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum LatestTransactionsVersion { standard, dashboard, token }

class LatestTransactions extends StatefulWidget {
  const LatestTransactions({
    super.key,
    this.version = LatestTransactionsVersion.standard,
  });
  final LatestTransactionsVersion version;

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
      description: context.l10n.latestTransactionsTransferDescription,
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
    final AccountBlock infoBlock =
    BlockUtils.isReceiveBlock(transactionBlock.blockType)
        ? transactionBlock.pairedAccountBlock!
        : transactionBlock;
    return <Widget>[
      if (isSelected)
        WidgetUtils.getMarqueeAddressTableCell(infoBlock.address, context)
      else
        WidgetUtils.getTextAddressTableCell(infoBlock.address, context),
      if (isSelected)
        WidgetUtils.getMarqueeAddressTableCell(infoBlock.toAddress, context)
      else
        WidgetUtils.getTextAddressTableCell(infoBlock.toAddress, context),
      if (isSelected)
        InfiniteScrollTableCell.withMarquee(
          infoBlock.hash.toString(),
          flex: 2,
        )
      else
        InfiniteScrollTableCell.withText(
          context,
          infoBlock.hash.toShortString(),
          flex: 2,
        ),
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
              builder: (String formattedAmount, String tokenSymbol) => Text(
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
            ? context.l10n.pending
            : _formatData(
          infoBlock.confirmationDetail!.momentumTimestamp * 1000,
        ),
      ),
      InfiniteScrollTableCell(_getTransactionTypeIcon(transactionBlock)),
      InfiniteScrollTableCell(
        infoBlock.token != null ? _showTokenSymbol(infoBlock) : Container(),
      ),
    ];
  }

  List<InfiniteScrollTableHeaderColumn> _getHeaderColumnsForTransferWidget() {
    return <InfiniteScrollTableHeaderColumn>[
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.sender,
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
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
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.amount,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.date,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.type,
        onSortArrowsPressed: _onSortArrowsPressed,
        contentAlign: MainAxisAlignment.center,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.assets,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
    ];
  }

  String _formatData(int transactionMillis) {
    final int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(days: 1).inMilliseconds) {
      return _formatDataShort(currentMillis - transactionMillis);
    }
    return FormatUtils.formatDate(
      transactionMillis,
      dateFormat: context.l10n.usDateFormat,
    );
  }

  String _formatDataShort(int i) {
    final Duration duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} ${context.l10n.hAgo}';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${context.l10n.minAgo}';
    }
    return '${duration.inSeconds} ${context.l10n.sAgo}';
  }

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
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
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
            : _transactions!.sort(
              (a, b) => b.toAddress.toString().compareTo(
            a.toAddress.toString(),
          ),
        );
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
            ? _transactions!
            .sort((a, b) => a.amount.compareTo(b.amount))
            : _transactions!
            .sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Date':
        _sortAscending
            ? _transactions!.sort(
              (a, b) => a.confirmationDetail!.momentumTimestamp.compareTo(
            b.confirmationDetail!.momentumTimestamp,
          ),
        )
            : _transactions!.sort(
              (a, b) => b.confirmationDetail!.momentumTimestamp.compareTo(
            a.confirmationDetail!.momentumTimestamp,
          ),
        );
        break;
      case 'Type':
        _sortAscending
            ? _transactions!
            .sort((a, b) => a.blockType.compareTo(b.blockType))
            : _transactions!
            .sort((a, b) => b.blockType.compareTo(a.blockType));
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

  List<InfiniteScrollTableHeaderColumn>
  _getHeaderColumnsForDashboardWidget() {
    return <InfiniteScrollTableHeaderColumn>[
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.sender,
        onSortArrowsPressed: _onSortArrowsPressed,
        flex: 2,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.amount,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.date,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.type,
        onSortArrowsPressed: _onSortArrowsPressed,
        contentAlign: MainAxisAlignment.center,
      ),
      InfiniteScrollTableHeaderColumn(
        columnName: context.l10n.assets,
        onSortArrowsPressed: _onSortArrowsPressed,
      ),
    ];
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
      if (isSelected)
        WidgetUtils.getMarqueeAddressTableCell(infoBlock.address, context)
      else
        WidgetUtils.getTextAddressTableCell(infoBlock.address, context),
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
              builder: (String formattedAmount, String tokenSymbol) => Text(
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
            ? context.l10n.pending
            : _formatData(
          infoBlock.confirmationDetail!.momentumTimestamp * 1000,
        ),
      ),
      InfiniteScrollTableCell(_getTransactionTypeIcon(transactionBlock)),
      InfiniteScrollTableCell(
        infoBlock.token != null ? _showTokenSymbol(infoBlock) : Container(),
      ),
    ];
  }

  String _getWidgetTitle() =>
      widget.version == LatestTransactionsVersion.token
          ? context.l10n.tokenTransactions
          : context.l10n.latestTransactionsTitle;
}

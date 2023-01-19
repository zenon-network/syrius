import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingList extends StatefulWidget {
  final StakingListBloc bloc;

  const StakingList(this.bloc, {Key? key}) : super(key: key);

  @override
  State createState() {
    return _StakingListState();
  }
}

class _StakingListState extends State<StakingList> {
  final List<StakeEntry> _stakingList = [];

  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Staking List',
      description: 'This card displays information about the staking entries '
          'for the specified address',
      childBuilder: () => _getTable(widget.bloc),
      onRefreshPressed: () => widget.bloc.refreshResults(),
    );
  }

  Widget _getTable(StakingListBloc bloc) {
    return InfiniteScrollTable<StakeEntry>(
      bloc: bloc,
      // This bloc is being used in another place, so it shouldn't be disposed
      // when this widget is disposed itself
      disposeBloc: false,
      headerColumns: [
        InfiniteScrollTableHeaderColumn(
          columnName: 'Amount',
          onSortArrowsPressed: _onSortArrowsPressed,
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Staking duration',
          onSortArrowsPressed: _onSortArrowsPressed,
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Recipient',
          onSortArrowsPressed: _onSortArrowsPressed,
          flex: 2,
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Expiration',
          onSortArrowsPressed: _onSortArrowsPressed,
        ),
        const InfiniteScrollTableHeaderColumn(columnName: ''),
      ],
      generateRowCells: (stakingItem, bool isSelected) {
        return [
          InfiniteScrollTableCell(
            FormattedAmountWithTooltip(
              amount: stakingItem.amount.addDecimals(
                kZnnCoin.decimals,
              ),
              tokenSymbol: kZnnCoin.symbol,
              builder: (formattedAmount, tokenSymbol) => Text(
                '$formattedAmount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: AppColors.subtitleColor,
                    ),
              ),
            ),
          ),
          InfiniteScrollTableCell.withText(
            context,
            _getStakingDurationInMonths(
              stakingItem.expirationTimestamp - stakingItem.startTimestamp,
            ),
          ),
          InfiniteScrollTableCell.tooltipWithText(
            context,
            stakingItem.address,
            flex: 2,
            showCopyToClipboardIcon: isSelected ? true : false,
          ),
          InfiniteScrollTableCell(
              _getCancelContainer(isSelected, stakingItem, bloc)),
          InfiniteScrollTableCell.withText(context, '')
        ];
      },
    );
  }

  Widget _getCancelContainer(
    bool isSelected,
    StakeEntry stakingItem,
    StakingListBloc stakingListModel,
  ) {
    return Stack(
      alignment: Alignment.centerLeft,
      fit: StackFit.loose,
      children: [
        stakingItem.expirationTimestamp * 1000 <
                DateTime.now().millisecondsSinceEpoch
            ? _getCancelButtonViewModel(
                stakingListModel,
                isSelected,
                stakingItem.id.toString(),
              )
            : _getCancelTimer(stakingItem, stakingListModel)
      ],
    );
  }

  ViewModelBuilder<CancelStakeBloc> _getCancelButtonViewModel(
    StakingListBloc bloc,
    bool isSelected,
    String stakeHash,
  ) {
    final GlobalKey<LoadingButtonState> cancelButtonKey = GlobalKey();

    return ViewModelBuilder<CancelStakeBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              cancelButtonKey.currentState?.animateReverse();
              bloc.refreshResults();
            }
          },
          onError: (error) {
            cancelButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while cancelling stake',
            );
          },
        );
      },
      builder: (_, model, __) => _getCancelButton(
        model,
        stakeHash,
        cancelButtonKey,
      ),
      viewModelBuilder: () => CancelStakeBloc(),
    );
  }

  Widget _getCancelButton(
    CancelStakeBloc model,
    String stakeHash,
    GlobalKey<LoadingButtonState> key,
  ) {
    return LoadingButton.infiniteScrollTableWithIcon(
      outlineColor: AppColors.errorColor,
      onPressed: () {
        key.currentState?.animateForward();
        model.cancelStake(stakeHash, context);
      },
      text: 'CANCEL',
      key: key,
      icon: const Icon(
        SimpleLineIcons.close,
        size: 11.0,
        color: AppColors.errorColor,
      ),
      textStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
            color: Theme.of(context).textTheme.bodyText1!.color,
          ),
    );
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Amount':
        _sortAscending
            ? _stakingList.sort((a, b) => a.amount.compareTo(b.amount))
            : _stakingList.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Staking duration':
        _sortAscending
            ? _stakingList.sort(
                (a, b) => (a.expirationTimestamp - a.startTimestamp)
                    .compareTo(b.expirationTimestamp - b.startTimestamp),
              )
            : _stakingList.sort(
                (a, b) => (b.expirationTimestamp - b.startTimestamp)
                    .compareTo(a.expirationTimestamp - a.startTimestamp),
              );
        break;
      case 'Recipient':
        _sortAscending
            ? _stakingList.sort((a, b) => a.address.compareTo(b.address))
            : _stakingList.sort((a, b) => b.address.compareTo(a.address));
        break;
      case 'Expiration':
        _sortAscending
            ? _stakingList.sort((a, b) =>
                a.expirationTimestamp.compareTo(b.expirationTimestamp))
            : _stakingList.sort((a, b) =>
                b.expirationTimestamp.compareTo(a.expirationTimestamp));
        break;
      default:
        _sortAscending
            ? _stakingList.sort((a, b) => a.address.compareTo(b.address))
            : _stakingList.sort((a, b) => b.address.compareTo(a.address));
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  Widget _getCancelTimer(
    StakeEntry stakingItem,
    StakingListBloc model,
  ) {
    int secondsUntilExpiration = stakingItem.expirationTimestamp -
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return CancelTimer(
      Duration(seconds: secondsUntilExpiration),
      AppColors.errorColor,
      onTimeFinishedCallback: () {
        model.refreshResults();
      },
    );
  }

  String _getStakingDurationInMonths(int seconds) {
    int numDays = seconds / 3600 ~/ 24;
    int numMonths = numDays ~/ 30;

    return '$numMonths month${numMonths > 1 ? 's' : ''}';
  }
}

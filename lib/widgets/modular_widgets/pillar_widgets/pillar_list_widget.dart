import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarListWidget extends StatefulWidget {

  const PillarListWidget({super.key, this.title});
  final String? title;

  @override
  State<PillarListWidget> createState() => _PillarListWidgetState();
}

class _PillarListWidgetState extends State<PillarListWidget> {
  final ScrollController _scrollController = ScrollController();

  final PagingController<int, PillarInfo> _pagingController = PagingController(
    firstPageKey: 0,
  );
  late StreamSubscription _blocListingStateSubscription;

  final PillarsListBloc _pillarsListBloc = PillarsListBloc();
  final DelegationInfoBloc _delegationInfoBloc = DelegationInfoBloc();

  final List<PillarInfo> _pillarInfoWrappers = <PillarInfo>[];

  final Map<String, GlobalKey<LoadingButtonState>> _delegateButtonKeys = <String, GlobalKey<LoadingButtonState>>{};

  bool _sortAscending = true;

  String? _currentlyDelegatingToPillar;

  int? _selectedRowIndex;

  DelegationInfo? _delegationInfo;

  @override
  void initState() {
    super.initState();
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
    _pagingController.addPageRequestListener((int pageKey) {
      _pillarsListBloc.onPageRequestSink.add(pageKey);
    });
    _blocListingStateSubscription = _pillarsListBloc.onNewListingState.listen(
      (InfiniteScrollBlocListingState<PillarInfo> listingState) {
        _pagingController.value = PagingState(
          nextPageKey: listingState.nextPageKey,
          error: listingState.error,
          itemList: listingState.itemList,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Pillar List',
      description: 'This card displays Pillar Nodes that are currently active '
          'in the network. The list contains the name of the Pillar, the '
          'associated producer address, the weight (total number of delegations) '
          'and your delegation status. You can choose to delegate your '
          '${kZnnCoin.symbol} balance to any Pillar in order to receive delegation '
          'rewards in ${kZnnCoin.symbol}. You can undelegate the balance at any '
          'time, without any penalties. Minimum delegation amount is 1 '
          '${kZnnCoin.symbol} per address',
      childBuilder: () => _getDelegationInfo(
        _pillarsListBloc,
        _delegationInfoBloc,
      ),
      onRefreshPressed: () {
        _delegationInfoBloc.updateStream();
        _pillarsListBloc.refreshResults();
      },
    );
  }

  Widget _getDelegationInfo(
    PillarsListBloc pillarsListBloc,
    DelegationInfoBloc delegationInfoBloc,
  ) {
    return StreamBuilder<DelegationInfo?>(
      stream: _delegationInfoBloc.stream,
      builder: (_, AsyncSnapshot<DelegationInfo?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            _delegationInfo = snapshot.data;
          } else {
            _delegationInfo = null;
          }
          return _getTable(pillarsListBloc);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getTable(PillarsListBloc bloc) {
    return Column(
      children: <Widget>[
        _getTableHeader(bloc),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: PagedListView<int, PillarInfo>(
              scrollController: _scrollController,
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<PillarInfo>(
                itemBuilder: (_, PillarInfo item, int index) => _getTableRow(
                  item,
                  index,
                ),
                firstPageProgressIndicatorBuilder: (_) =>
                    const SyriusLoadingWidget(),
                newPageProgressIndicatorBuilder: (_) =>
                    const SyriusLoadingWidget(),
                noMoreItemsIndicatorBuilder: (_) =>
                    const SyriusErrorWidget('No more items'),
                noItemsFoundIndicatorBuilder: (_) =>
                    const SyriusErrorWidget('No items found'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Container _getTableHeader(PillarsListBloc bloc) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color!,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Row(
          children: List<Widget>.from(
                <SizedBox>[
                  const SizedBox(
                    width: 20,
                  ),
                ],
              ) +
              <Widget>[
                InfiniteScrollTableHeaderColumn(
                  columnName: 'Name',
                  onSortArrowsPressed: _onSortArrowsPressed,
                ),
                InfiniteScrollTableHeaderColumn(
                  columnName: 'Producer Address',
                  onSortArrowsPressed: _onSortArrowsPressed,
                  flex: 3,
                ),
                InfiniteScrollTableHeaderColumn(
                  columnName: 'Weight',
                  onSortArrowsPressed: _onSortArrowsPressed,
                ),
                const InfiniteScrollTableHeaderColumn(columnName: 'Delegation'),
                const InfiniteScrollTableHeaderColumn(
                    columnName: 'Momentum reward',),
                const InfiniteScrollTableHeaderColumn(
                    columnName: 'Delegation reward',),
                const InfiniteScrollTableHeaderColumn(
                  columnName: 'Expected/produced momentums',
                ),
                const InfiniteScrollTableHeaderColumn(
                  columnName: 'Uptime',
                ),
                const InfiniteScrollTableHeaderColumn(
                  columnName: '',
                ),
                const SizedBox(
                  width: 5,
                ),
              ] +
              <Widget>[
                SizedBox(
                    width: 110,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Visibility(
                            visible: _delegationInfo?.name != null,
                            child: _getUndelegateButtonViewModel(bloc),
                          ),
                        ],),),
              ],),
    );
  }

  Widget _getTableRow(dynamic item, int indexOfRow) {
    final bool isSelected = _selectedRowIndex == indexOfRow;

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedRowIndex != indexOfRow) {
            _selectedRowIndex = indexOfRow;
          } else {
            _selectedRowIndex = null;
          }
        });
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 75,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          border: Border(
            top: indexOfRow != 0
                ? BorderSide(
                    color: Theme.of(context).dividerTheme.color!,
                    width: 0.75,
                  )
                : BorderSide.none,
            left: isSelected
                ? const BorderSide(
                    color: AppColors.znnColor,
                    width: 2,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
            children: List<Widget>.from(
                  <SizedBox>[
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ) +
                generateRowCells(item, isSelected) +
                <Widget>[
                  const SizedBox(
                    width: 110,
                  ),
                ],),
      ),
    );
  }

  bool _isStakeAddressDefault(PillarInfo pillarInfo) {
    return pillarInfo.ownerAddress.toString() == kSelectedAddress;
  }

  List<InfiniteScrollTableCell> generateRowCells(
    PillarInfo pillarInfo,
    bool isSelected,
  ) {
    return <InfiniteScrollTableCell>[
      InfiniteScrollTableCell.withText(
        context,
        pillarInfo.name,
        textColor: _isStakeAddressDefault(pillarInfo)
            ? AppColors.znnColor
            : AppColors.subtitleColor,
      ),
      InfiniteScrollTableCell.withText(
        context,
        pillarInfo.producerAddress.toString(),
        textColor: _isStakeAddressDefault(pillarInfo)
            ? AppColors.znnColor
            : AppColors.subtitleColor,
        flex: 3,
        showCopyToClipboardIcon: isSelected ? true : false,
      ),
      InfiniteScrollTableCell(
        FormattedAmountWithTooltip(
          amount: pillarInfo.weight.addDecimals(
            kZnnCoin.decimals,
          ),
          tokenSymbol: kZnnCoin.symbol,
          builder: (String formattedAmount, String tokenSymbol) => Text(
            '$formattedAmount $tokenSymbol',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: _isStakeAddressDefault(pillarInfo)
                      ? AppColors.znnColor
                      : AppColors.subtitleColor,
                ),
          ),
        ),
      ),
      InfiniteScrollTableCell(
        _getDelegateContainer(
          pillarInfo,
          _pillarsListBloc,
        ),
      ),
      InfiniteScrollTableCell.withText(
        context,
        '${pillarInfo.giveMomentumRewardPercentage} %',
      ),
      InfiniteScrollTableCell.withText(
        context,
        '${pillarInfo.giveDelegateRewardPercentage} %',
      ),
      InfiniteScrollTableCell.withText(context,
          '${pillarInfo.expectedMomentums}/${pillarInfo.producedMomentums} ',),
      InfiniteScrollTableCell.withText(
        context,
        '${_getMomentumsPercentage(pillarInfo)} %',
      ),
      InfiniteScrollTableCell(
        _getRevokeTimer(
          isSelected,
          pillarInfo,
          _pillarsListBloc,
        ),
      ),
    ];
  }

  Widget _getDelegateContainer(
    PillarInfo pillarInfo,
    PillarsListBloc model,
  ) {
    return Row(
      children: <Widget>[
        Visibility(
          visible: _currentlyDelegatingToPillar == null
              ? true
              : _currentlyDelegatingToPillar == pillarInfo.name,
          child: _delegationInfo == null
              ? _getBalanceStreamBuilder(pillarInfo, model)
              : Visibility(
                  visible: pillarInfo.name == _delegationInfo!.name,
                  child: _getUndelegateButtonViewModel(model),
                ),
        ),
      ],
    );
  }

  Widget _getDelegateButton(
    PillarInfo pillarInfo,
    DelegateButtonBloc model,
    GlobalKey<LoadingButtonState> key,
  ) {
    return LoadingButton.infiniteScrollTable(
      onPressed: () {
        key.currentState?.animateForward();
        setState(() {
          _currentlyDelegatingToPillar = pillarInfo.name;
        });
        model.delegateToPillar(pillarInfo.name);
      },
      text: 'DELEGATE',
      textStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
      key: key,
    );
  }

  Widget _getRevokeTimer(
    bool isSelected,
    PillarInfo pillarItem,
    PillarsListBloc model,
  ) {
    return Visibility(
      visible: _isStakeAddressDefault(pillarItem),
      child: Row(
        children: <Widget>[
          Visibility(
            visible: pillarItem.isRevocable,
            child: _getDisassemblePillarViewModel(
              isSelected,
              model,
              pillarItem,
            ),
          ),
          Visibility(
            visible: pillarItem.isRevocable,
            child: const SizedBox(
              width: 5,
            ),
          ),
          SizedBox( 
            child: pillarItem.isRevocable
                ? CancelTimer(
                    Duration(
                      seconds: pillarItem.revokeCooldown,
                    ),
                    AppColors.znnColor,
                    onTimeFinishedCallback: () {
                      model.refreshResults();
                    },
                  )
                : CancelTimer(
                    Duration(
                      seconds: pillarItem.revokeCooldown,
                    ),
                    AppColors.errorColor,
                    onTimeFinishedCallback: () {
                      model.refreshResults();
                    },
                  ),
          ),
          Expanded(
            child: StandardTooltipIcon(
              pillarItem.isRevocable
                  ? 'Revocation window is open'
                  : 'Until revocation window opens',
              Icons.help,
              iconColor: pillarItem.isRevocable
                  ? AppColors.znnColor
                  : AppColors.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDisassemblePillarViewModel(
    bool isSelected,
    PillarsListBloc pillarsListModel,
    PillarInfo pillarInfo,
  ) {
    return ViewModelBuilder<DisassemblePillarBloc>.reactive(
      onViewModelReady: (DisassemblePillarBloc model) {
        model.stream.listen(
          (AccountBlockTemplate? event) {
            if (event != null) {
              pillarsListModel.refreshResults();
            }
          },
          onError: (error) async {
            await NotificationUtils.sendNotificationError(
              error,
              'Error while disassembling Pillar',
            );
          },
        );
      },
      builder: (_, DisassemblePillarBloc model, __) => StreamBuilder<AccountBlockTemplate?>(
        stream: model.stream,
        builder: (_, AsyncSnapshot<AccountBlockTemplate?> snapshot) {
          if (snapshot.hasError) {
            return _getDisassembleButton(isSelected, model, pillarInfo);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getDisassembleButton(isSelected, model, pillarInfo);
            }
            return const SyriusLoadingWidget(size: 25);
          }
          return _getDisassembleButton(isSelected, model, pillarInfo);
        },
      ),
      viewModelBuilder: DisassemblePillarBloc.new,
    );
  }

  Widget _getDisassembleButton(
    bool isSelected,
    DisassemblePillarBloc model,
    PillarInfo pillarItem,
  ) {
    return MyOutlinedButton(
      minimumSize: const Size(55, 25),
      outlineColor: isSelected
          ? AppColors.errorColor
          : Theme.of(context).textTheme.titleSmall!.color,
      onPressed: isSelected
          ? () {
              model.disassemblePillar(
                context,
                pillarItem.name,
              );
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'DISASSEMBLE',
            style: isSelected
                ? Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    )
                : Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(
            width: 20,
          ),
          Icon(
            SimpleLineIcons.close,
            size: 11,
            color: isSelected
                ? AppColors.errorColor
                : Theme.of(context).textTheme.titleSmall!.color,
          ),
        ],
      ),
    );
  }

  Widget _getUndelegateButton(
    UndelegateButtonBloc model,
    GlobalKey<LoadingButtonState> key,
  ) {
    return LoadingButton.infiniteScrollTable(
      onPressed: () {
        key.currentState?.animateForward();
        model.cancelPillarVoting(context);
      },
      text: 'UNDELEGATE',
      textStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
      outlineColor: AppColors.errorColor,
      key: key,
    );
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Name':
        _sortAscending
            ? _pillarInfoWrappers.sort((PillarInfo a, PillarInfo b) => a.name.compareTo(b.name))
            : _pillarInfoWrappers.sort((PillarInfo a, PillarInfo b) => b.name.compareTo(a.name));
      case 'Producer Address':
        _sortAscending
            ? _pillarInfoWrappers
                .sort((PillarInfo a, PillarInfo b) => a.producerAddress.compareTo(b.producerAddress))
            : _pillarInfoWrappers
                .sort((PillarInfo a, PillarInfo b) => b.producerAddress.compareTo(a.producerAddress));
      case 'Weight':
        _sortAscending
            ? _pillarInfoWrappers.sort((PillarInfo a, PillarInfo b) => a.weight.compareTo(b.weight))
            : _pillarInfoWrappers.sort((PillarInfo a, PillarInfo b) => b.weight.compareTo(a.weight));
      default:
        _sortAscending
            ? _pillarInfoWrappers.sort((PillarInfo a, PillarInfo b) => a.name.compareTo(b.name))
            : _pillarInfoWrappers.sort((PillarInfo a, PillarInfo b) => b.name.compareTo(a.name));
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  Widget _getUndelegateButtonViewModel(PillarsListBloc pillarsModel) {
    final GlobalKey<LoadingButtonState> undelegateButtonKey = GlobalKey<LoadingButtonState>();

    return ViewModelBuilder<UndelegateButtonBloc>.reactive(
      onViewModelReady: (UndelegateButtonBloc model) {
        model.stream.listen(
          (AccountBlockTemplate? event) {
            if (event != null) {
              undelegateButtonKey.currentState?.animateReverse();
              _delegationInfoBloc.updateStream();
            }
          },
          onError: (error) async {
            undelegateButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              'Error while undelegating',
            );
          },
        );
      },
      builder: (_, UndelegateButtonBloc model, __) => _getUndelegateButton(
        model,
        undelegateButtonKey,
      ),
      viewModelBuilder: UndelegateButtonBloc.new,
    );
  }

  Widget _getBalanceStreamBuilder(
    PillarInfo pillarInfo,
    PillarsListBloc pillarsModel,
  ) {
    return StreamBuilder<Map<String?, AccountInfo>?>(
      stream: sl.get<BalanceBloc>().stream,
      builder: (_, AsyncSnapshot<Map<String?, AccountInfo>?> snapshot) {
        if (snapshot.hasError) {
          return Expanded(child: SyriusErrorWidget(snapshot.error!));
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getDelegateButtonViewModel(
              pillarInfo,
              pillarsModel,
              snapshot.data![kSelectedAddress]!,
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getDelegateButtonViewModel(
    PillarInfo pillarInfo,
    PillarsListBloc pillarsModel,
    AccountInfo accountInfo,
  ) {
    GlobalKey<LoadingButtonState> delegateButtonKey;

    if (_delegateButtonKeys[pillarInfo.name] == null) {
      _delegateButtonKeys[pillarInfo.name] = GlobalKey();
    }

    delegateButtonKey = _delegateButtonKeys[pillarInfo.name]!;

    return Visibility(
      visible: accountInfo.znn()! >= kMinDelegationAmount &&
          (_currentlyDelegatingToPillar == null
              ? true
              : _currentlyDelegatingToPillar == pillarInfo.name),
      child: ViewModelBuilder<DelegateButtonBloc>.reactive(
        onViewModelReady: (DelegateButtonBloc model) {
          model.stream.listen(
            (AccountBlockTemplate? event) {
              if (event != null) {
                _delegationInfoBloc.updateStream();
                delegateButtonKey.currentState?.animateReverse();
                setState(() {
                  _currentlyDelegatingToPillar = null;
                });
              }
            },
            onError: (error) async {
              delegateButtonKey.currentState?.animateReverse();
              await NotificationUtils.sendNotificationError(
                error,
                'Pillar delegation error',
              );
              setState(() {
                _currentlyDelegatingToPillar = null;
              });
            },
          );
        },
        builder: (_, DelegateButtonBloc model, __) => _getDelegateButton(
          pillarInfo,
          model,
          delegateButtonKey,
        ),
        viewModelBuilder: DelegateButtonBloc.new,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pillarsListBloc.dispose();
    _blocListingStateSubscription.cancel();
    super.dispose();
  }

  int _getMomentumsPercentage(PillarInfo pillarInfo) {
    final double percentage =
        pillarInfo.producedMomentums / pillarInfo.expectedMomentums * 100;
    if (percentage.isNaN) {
      return 0;
    }
    return percentage.round();
  }
}

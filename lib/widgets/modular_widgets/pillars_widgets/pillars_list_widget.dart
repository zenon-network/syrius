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

class PillarsListWidget extends StatefulWidget {
  final String? title;

  const PillarsListWidget({Key? key, this.title}) : super(key: key);

  @override
  State<PillarsListWidget> createState() => _PillarsListWidgetState();
}

class _PillarsListWidgetState extends State<PillarsListWidget> {
  final ScrollController _scrollController = ScrollController();

  final PagingController<int, PillarInfo> _pagingController = PagingController(
    firstPageKey: 0,
  );
  late StreamSubscription _blocListingStateSubscription;

  final PillarsListBloc _pillarsListBloc = PillarsListBloc();
  final DelegationInfoBloc _delegationInfoBloc = DelegationInfoBloc();

  final List<PillarInfo> _pillarInfoWrappers = [];

  final Map<String, GlobalKey<LoadingButtonState>> _delegateButtonKeys = {};

  bool _sortAscending = true;

  String? _currentlyDelegatingToPillar;

  int? _selectedRowIndex;

  DelegationInfo? _delegationInfo;

  @override
  void initState() {
    super.initState();
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
    _pagingController.addPageRequestListener((pageKey) {
      _pillarsListBloc.onPageRequestSink.add(pageKey);
    });
    _blocListingStateSubscription = _pillarsListBloc.onNewListingState.listen(
      (listingState) {
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
      builder: (_, snapshot) {
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
      children: [
        _getTableHeader(bloc),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: PagedListView<int, PillarInfo>(
              scrollController: _scrollController,
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<PillarInfo>(
                itemBuilder: (_, item, index) => _getTableRow(
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
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 15.0,
      ),
      child: Row(
          children: List<Widget>.from(
                [
                  const SizedBox(
                    width: 20.0,
                  )
                ],
              ) +
              [
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
                    columnName: 'Momentum reward'),
                const InfiniteScrollTableHeaderColumn(
                    columnName: 'Delegation reward'),
                const InfiniteScrollTableHeaderColumn(
                  columnName: 'Expected/produced momentums',
                ),
                const InfiniteScrollTableHeaderColumn(
                  columnName: 'Uptime',
                ),
                const InfiniteScrollTableHeaderColumn(
                  columnName: '',
                  flex: 1,
                ),
                const SizedBox(
                  width: 5.0,
                )
              ] +
              [
                SizedBox(
                    width: 110,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: _delegationInfo?.name != null,
                            child: _getUndelegateButtonViewModel(bloc),
                          ),
                        ])),
              ]),
    );
  }

  Widget _getTableRow(dynamic item, int indexOfRow) {
    bool isSelected = _selectedRowIndex == indexOfRow;

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
          minHeight: 75.0,
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
                    width: 2.0,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
            children: List<Widget>.from(
                  [
                    const SizedBox(
                      width: 20.0,
                    )
                  ],
                ) +
                generateRowCells(item, isSelected) +
                [
                  const SizedBox(
                    width: 110,
                  )
                ]),
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
    return [
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
          builder: (formattedAmount, tokenSymbol) => Text(
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
          '${pillarInfo.expectedMomentums}/${pillarInfo.producedMomentums} '),
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
      children: [
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
        children: [
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
              width: 5.0,
            ),
          ),
          Expanded(
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
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              pillarsListModel.refreshResults();
            }
          },
          onError: (error) {
            NotificationUtils.sendNotificationError(
              error,
              'Error while disassembling Pillar',
            );
          },
        );
      },
      builder: (_, model, __) => StreamBuilder<AccountBlockTemplate?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return _getDisassembleButton(isSelected, model, pillarInfo);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getDisassembleButton(isSelected, model, pillarInfo);
            }
            return const SyriusLoadingWidget(size: 25.0);
          }
          return _getDisassembleButton(isSelected, model, pillarInfo);
        },
      ),
      viewModelBuilder: () => DisassemblePillarBloc(),
    );
  }

  Widget _getDisassembleButton(
    bool isSelected,
    DisassemblePillarBloc model,
    PillarInfo pillarItem,
  ) {
    return MyOutlinedButton(
      minimumSize: const Size(55.0, 25.0),
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
        children: [
          Text(
            'DISASSEMBLE',
            style: isSelected
                ? Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    )
                : Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(
            width: 20.0,
          ),
          Icon(
            SimpleLineIcons.close,
            size: 11.0,
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
            ? _pillarInfoWrappers.sort((a, b) => a.name.compareTo(b.name))
            : _pillarInfoWrappers.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Producer Address':
        _sortAscending
            ? _pillarInfoWrappers
                .sort((a, b) => a.producerAddress.compareTo(b.producerAddress))
            : _pillarInfoWrappers
                .sort((a, b) => b.producerAddress.compareTo(a.producerAddress));
        break;
      case 'Weight':
        _sortAscending
            ? _pillarInfoWrappers.sort((a, b) => a.weight.compareTo(b.weight))
            : _pillarInfoWrappers.sort((a, b) => b.weight.compareTo(a.weight));
        break;
      default:
        _sortAscending
            ? _pillarInfoWrappers.sort((a, b) => a.name.compareTo(b.name))
            : _pillarInfoWrappers.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  Widget _getUndelegateButtonViewModel(PillarsListBloc pillarsModel) {
    final GlobalKey<LoadingButtonState> undelegateButtonKey = GlobalKey();

    return ViewModelBuilder<UndelegateButtonBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              undelegateButtonKey.currentState?.animateReverse();
              _delegationInfoBloc.updateStream();
            }
          },
          onError: (error) {
            undelegateButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while undelegating',
            );
          },
        );
      },
      builder: (_, model, __) => _getUndelegateButton(
        model,
        undelegateButtonKey,
      ),
      viewModelBuilder: () => UndelegateButtonBloc(),
    );
  }

  Widget _getBalanceStreamBuilder(
    PillarInfo pillarInfo,
    PillarsListBloc pillarsModel,
  ) {
    return StreamBuilder<Map<String?, AccountInfo>?>(
      stream: sl.get<BalanceBloc>().stream,
      builder: (_, snapshot) {
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
        onViewModelReady: (model) {
          model.stream.listen(
            (event) {
              if (event != null) {
                _delegationInfoBloc.updateStream();
                delegateButtonKey.currentState?.animateReverse();
                setState(() {
                  _currentlyDelegatingToPillar = null;
                });
              }
            },
            onError: (error) {
              delegateButtonKey.currentState?.animateReverse();
              NotificationUtils.sendNotificationError(
                error,
                'Pillar delegation error',
              );
              setState(() {
                _currentlyDelegatingToPillar = null;
              });
            },
          );
        },
        builder: (_, model, __) => _getDelegateButton(
          pillarInfo,
          model,
          delegateButtonKey,
        ),
        viewModelBuilder: () => DelegateButtonBloc(),
      ),
    );
  }

  @override
  void dispose() {
    _pillarsListBloc.dispose();
    _blocListingStateSubscription.cancel();
    super.dispose();
  }

  int _getMomentumsPercentage(PillarInfo pillarInfo) {
    double percentage =
        pillarInfo.producedMomentums / pillarInfo.expectedMomentums * 100;
    if (percentage.isNaN) {
      return 0;
    }
    return percentage.round();
  }
}

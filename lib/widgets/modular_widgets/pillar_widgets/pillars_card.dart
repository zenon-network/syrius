import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/models/models.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/infinite_scroll_table/infinite_scroll_table.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarsCard extends StatelessWidget {
  const PillarsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () async {
        context.read<PillarsBloc>().add(
          InfiniteListRefreshRequested(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
      body: BlocBuilder<PillarsBloc, InfiniteListState<PillarInfo>>(
        builder:
            (
              _,
              InfiniteListState<PillarInfo> state,
            ) {
              final InfiniteListStatus status = state.status;

              return switch (status) {
                InfiniteListStatus.initial => const SyriusLoadingWidget(),
                InfiniteListStatus.failure => SyriusErrorWidget(
                  state.error!,
                ),
                InfiniteListStatus.success => Populated(
                  hasReachedMax: state.hasReachedMax,
                  pillars: state.data!,
                ),
              };
            },
      ),
    );
  }

  CardData _buildCardData({
    required BuildContext context,
  }) {
    return CardData(
      description: context.l10n.pillarsListDescription(kZnnCoin.symbol),
      title: context.l10n.pillarsListTitle,
    );
  }
}

class Populated extends StatefulWidget {
  const Populated({
    required this.hasReachedMax,
    required this.pillars,
    super.key,
  });

  final bool hasReachedMax;
  final List<PillarInfo> pillars;

  @override
  State<Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<Populated> {
  final ScrollController _scrollController = ScrollController();

  final PagingController<int, PillarInfo> _pagingController = PagingController(
    firstPageKey: 0,
  );
  late StreamSubscription _blocListingStateSubscription;

  final PillarsListBloc _pillarsListBloc = PillarsListBloc();
  final DelegationInfoBloc _delegationInfoBloc = DelegationInfoBloc();

  final List<PillarInfo> _pillarInfoWrappers = <PillarInfo>[];

  final Map<String, GlobalKey<LoadingButtonState>> _delegateButtonKeys =
      <String, GlobalKey<LoadingButtonState>>{};

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
    return InfiniteScrollTable<PillarInfo>(
      items: widget.pillars,
      hasReachedMax: widget.hasReachedMax,
      columns: _buildHeaderColumns(),
      generateRowCells: _rowCellsGenerator,
      onScrollReachedBottom: () {
        context.read<LatestTransactionsBloc>().add(
          InfiniteListMoreRequested(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
    );
    return CardScaffold(
      title: context.l10n.pillarsListTitle,
      description: context.l10n.pillarsListDescription(kZnnCoin.symbol),
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
                    SyriusErrorWidget(context.l10n.noMoreItems),
                noItemsFoundIndicatorBuilder: (_) =>
                    SyriusErrorWidget(context.l10n.noItemsFound),
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
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Visibility(
                  visible: _delegationInfo?.name != null,
                  child: _getUndelegateButtonViewModel(bloc),
                ),
              ],
            ),
          ),
        ],
      ),
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
          children:
              List<Widget>.from(
                <SizedBox>[
                  const SizedBox(
                    width: 20,
                  ),
                ],
              ) +
              <Widget>[
                const SizedBox(
                  width: 110,
                ),
              ],
        ),
      ),
    );
  }

  bool _isStakeAddressDefault(PillarInfo pillarInfo) {
    return pillarInfo.ownerAddress.toString() == kSelectedAddress;
  }

  List<InfiniteScrollTableCell> _rowCellsGenerator(
    PillarInfo pillarInfo,
  ) {
    return <InfiniteScrollTableCell>[
      InfiniteScrollTableCell.withText(
        content: pillarInfo.name,
        textStyle: TextStyle(
          color: _isStakeAddressDefault(pillarInfo)
              ? AppColors.znnColor
              : AppColors.subtitleColor,
        ),
      ),
      InfiniteScrollTableCell.textFromAddress(
        address: pillarInfo.producerAddress,
        flex: 3,
        isStakeAddress: _isStakeAddressDefault(pillarInfo),
      ),
      InfiniteScrollTableCell(
        child: FormattedAmountWithTooltip(
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
        child: _getDelegateContainer(
          pillarInfo,
          _pillarsListBloc,
        ),
      ),
      InfiniteScrollTableCell.withText(
        content: '${pillarInfo.giveMomentumRewardPercentage} %',
      ),
      InfiniteScrollTableCell.withText(
        content: '${pillarInfo.giveDelegateRewardPercentage} %',
      ),
      InfiniteScrollTableCell.withText(
        content:
            '${pillarInfo.expectedMomentums}/${pillarInfo.producedMomentums} ',
      ),
      InfiniteScrollTableCell.withText(
        content: '${_getMomentumsPercentage(pillarInfo)} %',
      ),
      InfiniteScrollTableCell(
        child: _getRevokeTimer(
          pillarInfo,
          _pillarsListBloc,
        ),
      ),
      InfiniteScrollTableCell.withText(content: 'Button'),
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
      text: context.l10n.delegateKey,
      textStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
        color: Theme.of(context).textTheme.bodyLarge!.color,
      ),
      key: key,
    );
  }

  Widget _getRevokeTimer(
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
                  ? context.l10n.revocationWindowOpen
                  : context.l10n.untilRevocationWindowOpens,
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
              context.l10n.errorDisassemblingPillar,
            );
          },
        );
      },
      builder: (_, DisassemblePillarBloc model, __) =>
          StreamBuilder<AccountBlockTemplate?>(
            stream: model.stream,
            builder: (_, AsyncSnapshot<AccountBlockTemplate?> snapshot) {
              if (snapshot.hasError) {
                return _getDisassembleButton(model, pillarInfo);
              }
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  return _getDisassembleButton(model, pillarInfo);
                }
                return const SyriusLoadingWidget(size: 25);
              }
              return _getDisassembleButton(model, pillarInfo);
            },
          ),
      viewModelBuilder: DisassemblePillarBloc.new,
    );
  }

  Widget _getDisassembleButton(
    DisassemblePillarBloc model,
    PillarInfo pillarItem,
  ) {
    return MyOutlinedButton(
      minimumSize: const Size(55, 25),
      outlineColor: AppColors.errorColor,
      // TODO(maznnwell): add confirmation dialog
      onPressed: () {
              model.disassemblePillar(
                context,
                pillarItem.name,
              );
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.l10n.disassemble,
            style:Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
          ),
          const SizedBox(
            width: 20,
          ),
          Icon(
            SimpleLineIcons.close,
            size: 11,
            color: AppColors.errorColor,
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
      text: context.l10n.undelegate,
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
            ? _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) => a.name.compareTo(b.name),
              )
            : _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) => b.name.compareTo(a.name),
              );
      case 'Producer Address':
        _sortAscending
            ? _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) =>
                    a.producerAddress.compareTo(b.producerAddress),
              )
            : _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) =>
                    b.producerAddress.compareTo(a.producerAddress),
              );
      case 'Weight':
        _sortAscending
            ? _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) => a.weight.compareTo(b.weight),
              )
            : _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) => b.weight.compareTo(a.weight),
              );
      default:
        _sortAscending
            ? _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) => a.name.compareTo(b.name),
              )
            : _pillarInfoWrappers.sort(
                (PillarInfo a, PillarInfo b) => b.name.compareTo(a.name),
              );
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  Widget _getUndelegateButtonViewModel(PillarsListBloc pillarsModel) {
    final GlobalKey<LoadingButtonState> undelegateButtonKey =
        GlobalKey<LoadingButtonState>();

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
              context.l10n.errorUndelegating,
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
      visible:
          accountInfo.znn()! >= kMinDelegationAmount &&
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
                context.l10n.pillarDelegationError,
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

  List<InfiniteScrollTableColumnType> _buildHeaderColumns() => [
    .pillarName,
    .producerAddress,
    .weight,
    .delegation,
    .momentumReward,
    .delegationReward,
    .expectedProducedMomentums,
    .uptime,
    // For the disassemble timer
    .blank,
    .undelegate,
  ];
}

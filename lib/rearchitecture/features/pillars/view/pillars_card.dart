import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DelegationCubit, DelegationState>(
      builder: (BuildContext context, DelegationState state) {
        final Widget table = InfiniteScrollTable<PillarInfo>(
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

        if (state.status == TimerStatus.success) {
          _delegationInfo = state.data;
        }

        return switch (state.status) {
          TimerStatus.initial => const SyriusLoadingWidget(),
          TimerStatus.loading => const SyriusLoadingWidget(),
          TimerStatus.failure =>
            state.error! is NoDelegationStatsException
                ? table
                : SyriusErrorWidget(state.error!),
          TimerStatus.success => table,
        };
      },
    );
  }

  bool _isOwnerAddressSelected(PillarInfo pillarInfo) {
    return pillarInfo.ownerAddress.toString() == kSelectedAddress;
  }

  List<InfiniteScrollTableCell> _rowCellsGenerator(
    PillarInfo pillarInfo,
  ) {
    return <InfiniteScrollTableCell>[
      InfiniteScrollTableCell.withText(
        content: pillarInfo.name,
        textStyle: TextStyle(
          color: _isOwnerAddressSelected(pillarInfo)
              ? AppColors.znnColor
              : AppColors.subtitleColor,
        ),
      ),
      InfiniteScrollTableCell.textFromAddress(
        address: pillarInfo.producerAddress,
        flex: 3,
        isStakeAddress: _isOwnerAddressSelected(pillarInfo),
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
              color: _isOwnerAddressSelected(pillarInfo)
                  ? AppColors.znnColor
                  : AppColors.subtitleColor,
            ),
          ),
        ),
      ),
      InfiniteScrollTableCell(
        child: _getDelegateContainer(
          pillarInfo,
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
    ];
  }

  Widget _getDelegateContainer(
    PillarInfo pillarInfo,
  ) {
    return Row(
      children: <Widget>[
        Visibility(
          visible: _currentlyDelegatingToPillar == null
              ? true
              : _currentlyDelegatingToPillar == pillarInfo.name,
          child: _delegationInfo == null
              ? _getBalanceStreamBuilder(pillarInfo)
              : Visibility(
                  visible: pillarInfo.name == _delegationInfo!.name,
                  child: const Text('Undelegate'),
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

  Widget _getBalanceStreamBuilder(
    PillarInfo pillarInfo,
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
                unawaited(
                  context.read<DelegationCubit>().fetchDataPeriodically(),
                );
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
  ];
}

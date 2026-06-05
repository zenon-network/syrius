import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the list of pillars, each UI item from the list
/// showing some specific information about the represented pillar
///
/// If a user has delegated to a pillar, a 'Delegated' mention is shown
/// If a user hasn't delegated to a pillar, than a 'Delegate' button is shown
/// which allow the user to delegate without un-delegating first
class PillarsCard extends StatelessWidget {
  /// {@macro default_constructor}
  const PillarsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<PillarsBloc>(
          create: (_) =>
          PillarsBloc(zenon: zenon!)
            ..add(const InfiniteListRequested(address: null)),
        ),
        BlocProvider<DelegationBloc>(
          create: (_) => DelegationBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
      ],
      child: const _View(),
    );
  }
}


class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
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
                InfiniteListStatus.success => _Populated(
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
      title: context.l10n.pillars,
    );
  }
}

class _Populated extends StatefulWidget {
  const _Populated({
    required this.hasReachedMax,
    required this.pillars,
  });

  final bool hasReachedMax;
  final List<PillarInfo> pillars;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {
  final List<PillarInfo> _pillarInfoWrappers = <PillarInfo>[];

  final Map<String, GlobalKey<LoadingButtonState>> _delegateButtonKeys =
      <String, GlobalKey<LoadingButtonState>>{};

  bool _sortAscending = true;

  String? _currentlyDelegatingToPillar;

  DelegationInfo? _delegationInfo;

  GlobalKey<LoadingButtonState>? _currentlyActiveButtonKey;

  AccountInfo? _accountInfo;

  @override
  void initState() {
    super.initState();
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MultipleBalanceState multipleBalanceState = context
        .watch<MultipleBalanceBloc>()
        .state;

    if (multipleBalanceState.status == .initial ||
        multipleBalanceState.status == .loading) {
      return const SyriusLoadingWidget();
    } else if (multipleBalanceState.status == .failure) {
      return SyriusErrorWidget(multipleBalanceState.error!);
    } else {
      _accountInfo = multipleBalanceState.data![kSelectedAddress!];
    }

    return BlocListener<DelegationBloc, DelegationState>(
      listener: (_, DelegationState state) {
        if (state is DelegationDone) {
          context.read<DelegationStatsBloc>().add(
            FetchRequestData(address: Address.parse(kSelectedAddress!)),
          );
          _currentlyActiveButtonKey?.currentState?.animateReverse();
          setState(() {
            _currentlyDelegatingToPillar = null;
          });
        } else if (state is DelegationFailure) {
          _currentlyActiveButtonKey?.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.pillarDelegationError,
            ),
          );
          setState(() {
            _currentlyDelegatingToPillar = null;
          });
        }
      },
      child: BlocBuilder<DelegationStatsBloc, FetchState<DelegationInfo>>(
        builder: (BuildContext context, FetchState<DelegationInfo> state) {
          final Widget table = InfiniteScrollTable<PillarInfo>(
            itemKeyGenerator: (PillarInfo pillarInfo) =>
                ValueKey<String>(pillarInfo.name),
            items: widget.pillars,
            hasReachedMax: widget.hasReachedMax,
            columns: _buildHeaderColumns(),
            generateRowCells: _rowCellsGenerator,
            onScrollReachedBottom: () {
              context.read<PillarsBloc>().add(
                const InfiniteListMoreRequested(
                  address: null,
                ),
              );
            },
          );

          if (state is FetchPopulated<DelegationInfo>) {
            _delegationInfo = state.data;
          }

          return switch (state) {
            FetchFailure<DelegationInfo>() =>
              state.exception is NoDelegationStatsException
                  ? table
                  : SyriusErrorWidget(state.exception),
            FetchInitial<DelegationInfo>() => const SyriusLoadingWidget(),
            FetchPopulated<DelegationInfo>() => table,
          };
        },
      ),
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
        child: _buildDelegateCell(
          pillarInfo: pillarInfo,
        ),
      ),
    ];
  }

  Widget _buildDelegateCell({
    required PillarInfo pillarInfo,
  }) {
    final bool currentlyDelegatingToAPillar =
        _currentlyDelegatingToPillar != null;
    final bool currentlyDelegatingToThisPillar =
        _currentlyDelegatingToPillar == pillarInfo.name;

    final bool delegatedToThisPillar = _delegationInfo?.name == pillarInfo.name;

    if (currentlyDelegatingToThisPillar) {
      return _buildDelegateButton(pillarInfo: pillarInfo);
    } else if (delegatedToThisPillar) {
      // TODO(maznnwell): check if we can tell with how many ZNN were delegated
      return const Text(
        'Delegated',
        style: TextStyle(
          color: AppColors.znnColor,
        ),
        textAlign: .center,
      );
    }
    if (currentlyDelegatingToAPillar) {
      return const SizedBox.shrink();
    } else {
      return _buildDelegateButton(pillarInfo: pillarInfo);
    }
  }

  // TODO(maznnwell): to be used when sorting is enabled
  // ignore: unused_element
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
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  Widget _buildDelegateButton({
    required PillarInfo pillarInfo,
  }) {
    _delegateButtonKeys[pillarInfo.name] ??= GlobalKey<LoadingButtonState>();
    final GlobalKey<LoadingButtonState> delegateButtonKey =
        _delegateButtonKeys[pillarInfo.name]!;

    return Row(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: <Widget>[
        Visibility(
          visible: _accountInfo!.znn()! >= kMinDelegationAmount,
          child: LoadingButton(
            onPressed: () {
              delegateButtonKey.currentState?.animateForward();
              setState(() {
                _currentlyDelegatingToPillar = pillarInfo.name;
                _currentlyActiveButtonKey = delegateButtonKey;
              });
              context.read<DelegationBloc>().add(
                DelegationRequested(
                  address: Address.parse(kSelectedAddress!),
                  pillarName: pillarInfo.name,
                ),
              );
            },
            text: context.l10n.delegateKey.capitalize(),
            textStyle: const TextStyle(
              color: Colors.white,
            ),
            key: delegateButtonKey,
          ),
        ),
      ],
    );
  }

  int _getMomentumsPercentage(PillarInfo pillarInfo) {
    final double percentage =
        pillarInfo.producedMomentums / pillarInfo.expectedMomentums * 100;
    if (percentage.isNaN) {
      return 0;
    }
    return percentage.round();
  }

  List<InfiniteScrollTableColumnType> _buildHeaderColumns() =>
      <InfiniteScrollTableColumnType>[
        .pillarName,
        .producerAddress,
        .weight,
        .momentumReward,
        .delegationReward,
        .expectedProducedMomentums,
        .uptime,
        .delegation,
      ];
}

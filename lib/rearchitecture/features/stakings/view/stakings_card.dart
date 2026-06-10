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

/// A card that displays staking entries for the selected address.
class StakingsCard extends StatelessWidget {
  /// Creates a staking list card.
  const StakingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<CancelStakeBloc>(
          create: (_) => CancelStakeBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
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
      onRefreshPressed: () => _refreshStakings(context),
      body: BlocBuilder<StakingsBloc, InfiniteListState<StakeEntry>>(
        builder: (_, InfiniteListState<StakeEntry> state) {
          return switch (state.status) {
            InfiniteListStatus.initial => const SyriusLoadingWidget(),
            InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
            InfiniteListStatus.success => _Populated(
              hasReachedMax: state.hasReachedMax,
              stakings: state.data!,
            ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    description: context.l10n.stakingsListDescription,
    title: context.l10n.stakingsListTitle,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this.hasReachedMax,
    required this.stakings,
  });

  final bool hasReachedMax;
  final List<StakeEntry> stakings;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<StakeEntry>(
      itemKeyGenerator: (StakeEntry stakeEntry) =>
          ValueKey<String>(stakeEntry.id.toString()),
      items: stakings,
      hasReachedMax: hasReachedMax,
      columns: _buildHeaderColumns(),
      generateRowCells: (StakeEntry stakeEntry) => _buildRowCells(
        context: context,
        stakeEntry: stakeEntry,
      ),
      onScrollReachedBottom: () {
        context.read<StakingsBloc>().add(
          InfiniteListMoreRequested(address: Address.parse(kSelectedAddress!)),
        );
      },
    );
  }

  List<InfiniteScrollTableCell> _buildRowCells({
    required BuildContext context,
    required StakeEntry stakeEntry,
  }) {
    return <InfiniteScrollTableCell>[
      InfiniteScrollTableCell(
        child: FormattedAmountWithTooltip(
          amount: stakeEntry.amount.addDecimals(kZnnCoin.decimals),
          tokenSymbol: kZnnCoin.symbol,
          builder: (String formattedAmount, String tokenSymbol) => Text(
            '$formattedAmount $tokenSymbol',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: AppColors.subtitleColor,
            ),
          ),
        ),
      ),
      InfiniteScrollTableCell.withText(
        content: _getStakingDurationInMonths(
          stakeEntry.expirationTimestamp - stakeEntry.startTimestamp,
        ),
      ),
      InfiniteScrollTableCell.textFromAddress(
        address: stakeEntry.address,
      ),
      InfiniteScrollTableCell(
        child: _buildExpirationCell(context: context, stakeEntry: stakeEntry),
      ),
    ];
  }

  Widget _buildExpirationCell({
    required BuildContext context,
    required StakeEntry stakeEntry,
  }) {
    if (_isStakeExpired(stakeEntry)) {
      return _buildCancelStakeBlocConsumer(
        context: context,
        stakeHash: stakeEntry.id,
      );
    }

    return Row(
      children: <Widget>[
        CancelTimer(
          Duration(seconds: _secondsUntilExpiration(stakeEntry)),
          AppColors.errorColor,
          onTimeFinishedCallback: () => _refreshStakings(context),
        ),
      ],
    );
  }

  Widget _buildCancelStakeBlocConsumer({
    required BuildContext context,
    required Hash stakeHash,
  }) {
    return Row(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: <Widget>[
        BlocConsumer<CancelStakeBloc, CancelStakeState>(
          listener: (_, CancelStakeState state) {
            if (state is CancelStakeDone) {
              _refreshStakings(context);
            } else if (state is CancelStakeFailure) {
              unawaited(
                NotificationUtils.sendNotificationError(
                  state.exception,
                  context.l10n.errorWhileCancellingStake,
                ),
              );
            }
          },
          builder: (_, CancelStakeState state) {
            return switch (state) {
              CancelStakeLoading() => const SyriusLoadingWidget(size: 25),
              _ => _buildCancelButton(
                context: context,
                stakeHash: stakeHash,
              ),
            };
          },
        ),
      ],
    );
  }

  Widget _buildCancelButton({
    required BuildContext context,
    required Hash stakeHash,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        iconColor: AppColors.errorColor,
        side: const BorderSide(color: AppColors.errorColor),
      ),
      onPressed: () {
        context.read<CancelStakeBloc>().add(
          CancelStakeRequested(stakeHash: stakeHash),
        );
      },
      label: Text(
        context.l10n.cancel.toUpperCase(),
        style: TextStyle(
          color: context.newThemeData.textTheme.titleSmall!.color,
        ),
      ),
      icon: const Icon(Icons.close),
    );
  }

  List<InfiniteScrollTableColumnType>
  _buildHeaderColumns() => <InfiniteScrollTableColumnType>[
    .amount,
    .stakingDuration,
    // TODO(maznnwell): check if you can stake from an address for another one
    .recipientAddress,
    .expiration,
  ];

  bool _isStakeExpired(StakeEntry stakeEntry) =>
      stakeEntry.expirationTimestamp * 1000 <
      DateTime.now().millisecondsSinceEpoch;

  int _secondsUntilExpiration(StakeEntry stakeEntry) =>
      stakeEntry.expirationTimestamp -
      DateTime.now().millisecondsSinceEpoch ~/ 1000;

  String _getStakingDurationInMonths(int seconds) {
    final int numDays = seconds / 3600 ~/ 24;
    final int numMonths = numDays ~/ 30;

    return '$numMonths month${numMonths > 1 ? 's' : ''}';
  }
}

void _refreshStakings(BuildContext context) {
  context.read<StakingsBloc>().add(
    InfiniteListRefreshRequested(address: Address.parse(kSelectedAddress!)),
  );
}

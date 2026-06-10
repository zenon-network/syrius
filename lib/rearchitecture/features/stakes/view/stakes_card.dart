import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
class StakesCard extends StatelessWidget {
  /// Creates a stakes list card.
  const StakesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () => _refreshStakes(context),
      body: BlocBuilder<StakesBloc, InfiniteListState<StakeEntry>>(
        builder: (_, InfiniteListState<StakeEntry> state) {
          return switch (state.status) {
            InfiniteListStatus.initial => const SyriusLoadingWidget(),
            InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
            InfiniteListStatus.success => _Populated(
              hasReachedMax: state.hasReachedMax,
              stakes: state.data!,
            ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    description: context.l10n.stakesListDescription,
    title: context.l10n.stakesListTitle,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this.hasReachedMax,
    required this.stakes,
  });

  final bool hasReachedMax;
  final List<StakeEntry> stakes;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<StakeEntry>(
      itemKeyGenerator: (StakeEntry stakeEntry) =>
          ValueKey<String>(stakeEntry.id.toString()),
      items: stakes,
      hasReachedMax: hasReachedMax,
      columns: _buildHeaderColumns(),
      generateRowCells: (StakeEntry stakeEntry) => _buildRowCells(
        context: context,
        stakeEntry: stakeEntry,
      ),
      onScrollReachedBottom: () {
        context.read<StakesBloc>().add(
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
      return CancelStakeButton(
        stakeHash: stakeEntry.id,
        onCancelled: () => _refreshStakes(context),
      );
    }

    return Row(
      mainAxisAlignment: .center,
      children: <Widget>[
        CancelTimer(
          Duration(seconds: _secondsUntilExpiration(stakeEntry)),
          AppColors.errorColor,
          onTimeFinishedCallback: () => _refreshStakes(context),
        ),
      ],
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

void _refreshStakes(BuildContext context) {
  context.read<StakesBloc>().add(
    InfiniteListRefreshRequested(address: Address.parse(kSelectedAddress!)),
  );
}

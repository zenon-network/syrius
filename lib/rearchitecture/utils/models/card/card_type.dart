import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';

/// A class that helps distinguish between the card widgets
enum CardType {
  /// A type for a card displaying information related to balance
  balance,
  /// A type for a card displaying information related to delegation
  delegationStats,
  /// A type for a card displaying information related to ZNN and QSR
  dualCoinStats,
  /// A type for a card displaying information related to pillars
  pillars,
  /// A type for a card displaying information in realtime
  realtimeStatistics,
  /// A type for a card displaying information related to sentinels
  sentinels,
  /// A type for a card displaying information related to staking
  staking,
  /// A type for a card displaying information related to transactions
  /// confirmed in the last hour
  totalHourlyTransactions,
  /// A type for a card that redirects to the Transfer tab
  transfer;

  /// Returns the [CardData] assigned to a specific [CardType] value.
  ///
  /// The parameter [context] is used to retrieve the localized strings
  CardData getData({
    required BuildContext context,
  }) {
    return switch (this) {
      CardType.balance => CardData(
          title: context.l10n.balance,
          description: context.l10n.currentAmounts(
            kQsrCoin.symbol,
            kZnnCoin.symbol,
          ),
        ),
      CardType.delegationStats => CardData(
          title: context.l10n.delegationStats,
          description: context.l10n.delegationStatsDescription(kZnnCoin.symbol),
        ),
      CardType.dualCoinStats => CardData(
          title: context.l10n.dualCoinStats,
          description: context.l10n.dualCoinStatsDescription(
            kQsrCoin.symbol,
            kZnnCoin.symbol,
          ),
        ),
      CardType.pillars => CardData(
          title: context.l10n.pillars,
          description: context.l10n.pillarsDescription,
        ),
      CardType.realtimeStatistics => CardData(
          title: context.l10n.realtimeStats,
          description: context.l10n
              .realtimeStatsDescription(kQsrCoin.symbol, kZnnCoin.symbol),
        ),
      CardType.sentinels => CardData(
          title: context.l10n.sentinels,
          description: context.l10n.sentinelsDescription,
        ),
      CardType.staking => CardData(
          description: context.l10n.stakingStatsDescription(kZnnCoin.symbol),
          title: context.l10n.stakingStats,
        ),
      CardType.totalHourlyTransactions => CardData(
          description: context.l10n.transactionsDescription,
          title: context.l10n.transactions,
        ),
      CardType.transfer => CardData(
          description: context.l10n.transferDescription,
          title: context.l10n.transfer,
        ),
    };
  }
}
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card_data.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';

enum CardType {
  balance,
  delegationStats,
  dualCoinStats,
  pillars,
  realtimeStatistics,
  sentinels,
  staking,
  totalHourlyTransactions,
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

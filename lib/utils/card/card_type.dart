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
          description: 'This card displays the current ${kZnnCoin.symbol} '
              'and ${kQsrCoin.symbol} amounts for the selected address',
        ),
      CardType.delegationStats => CardData(
          title: context.l10n.delegationStats,
          description: 'This card displays the amount of ${kZnnCoin.symbol} '
              'and the name of the Pillar that you delegated to',
        ),
      CardType.dualCoinStats => CardData(
          title: context.l10n.dualCoinStats,
          description: 'This card displays the circulating ${kZnnCoin.symbol} '
              'and ${kQsrCoin.symbol} supply from the network',
        ),
      CardType.pillars => CardData(
          title: 'Pillars',
          description: 'This card displays the number of active '
              'Pillars in the network',
        ),
      CardType.realtimeStatistics => CardData(
          title: 'Realtime Stats',
          description:
              'This card displays the number of ${kZnnCoin.symbol} and '
              '${kQsrCoin.symbol} transactions. For example, a delegation is '
              "considered a ${kZnnCoin.symbol} transaction from the network's "
              'perspective. Every interaction with the network embedded '
              'contracts is internally considered a transaction',
        ),
      CardType.sentinels => CardData(
          title: 'Sentinels',
          description: 'This card displays the number of active '
              'Sentinels in the network',
        ),
      CardType.staking => CardData(
          description: 'This card displays the number of staking '
              'entries and the total ${kZnnCoin.symbol} that you are currently '
              'staking',
          title: 'Staking Stats',
        ),
      CardType.totalHourlyTransactions => CardData(
          description: 'This card displays the total number of '
              'transactions settled in the last hour across the network',
          title: 'Transactions',
        ),
      CardType.transfer => CardData(
          description: 'Redirects you to the Transfer tab where you '
              'can manage sending and receiving funds',
          title: 'Transfer',
        ),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card_data.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';

enum CardType {
  balance,
  delegationStats,
  dualCoinStats,
  pillars,
  realtimeStatistics;

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
    };
  }
}

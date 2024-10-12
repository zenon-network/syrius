import 'package:zenon_syrius_wallet_flutter/utils/card/card_data.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';

enum CardType {
  balance,
  delegationStats;

  CardData get data {
    return switch (this) {
      CardType.balance => CardData(
        title: 'Balance',
        description: 'This card displays the current ${kZnnCoin.symbol} '
            'and ${kQsrCoin.symbol} amounts for the selected address',
      ),
      CardType.delegationStats => CardData(
        title: 'Delegation Stats',
        description: 'This card displays the amount of ${kZnnCoin.symbol} '
            'and the name of the Pillar that you delegated to',
      ),
    };
  }
}
